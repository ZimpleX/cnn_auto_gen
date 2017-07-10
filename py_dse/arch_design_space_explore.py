import pdb
import numpy as np
import math
from zython.logf.printf import printf
"""
If the memory can not hold the entire set, split it: 2x, 4x, ... does not matter.
	e.g., if you split four times, making f_in become f_in/4, f_out keeps unchanged.
	then just let CPU merge the 4 set of f_out*N**2 --> it's gonna be fast, 400 accumulation becomes 404 accumulations.
"""


"""
############################################
# THROUGHPUT UNIT: COMPLEX WORDS PER CYCLE #
############################################
N: FFT
q_1dfft: folding factor for 1d fft pipeline
q_2dfft: folding factor for 2d fft pipeline
q_1difft: folding factor for 1d ifft pipeline
q_2difft: folding factor for 2d ifft pipeline
P_fft: number of N x N 2D FFT
P_ifft: number of N x N 2D IFFT
M_img (words): image buffer size
M_kern: kernel buffer size
P_mac: number of N x N tiles the MAC can handle
q_mac: folding factor for MAC
		i.e.: the throughput for MAC is P_mac * N*N / q_mac
"""

"""
OaA first two layers (64 point): latency = 2.719 M cycles
OaA last three layers (16 point): latency = 
CaP all five layers (64 point): average latency = 2.267 M cycles
"""



bytePerWord = 4	# 16-bit fixed point COMPLEX word
clkRate = 200e6	# fixed for harp: 200M Hz

N = 16			# for now, fixed for all 
x = 4
#config_setting_set = [{"pick_layers": },{""}]
config_setting = {"pick_layers":-3}
# meta data for all convolution layers
if config_setting["pick_layers"] == -3:
	layers = {	"f_in": [256.,384.,384.],
				"f_out":[384.,384.,256.],
				"l_img":[27.,13.,13.],		# l_img should be the image after folding
				"l_kern":[3.,3.,3.]}
elif config_setting["pick_layers"] == -4:
	layers = {	"f_in": [96,256,384,384],
				"f_out":[256,384,384,256],
				"l_img":[55,27,13,13],
				"l_kern":[5,3,3,3]
				}
elif config_setting["pick_layers"] == 2:
	layers = {	"f_in": [3.,96.],
				"f_out":[96.,256.],
				"l_img":[224.,55.],		# l_img should be the image after folding
				"l_kern":[11.,5.]}
elif config_setting["pick_layers"] == 5:
	layers = { 	"f_in": [3.,96.,256.,384.,384],
				"f_out":[96.,256.,384.,384.,256.],
				"l_img":[224.,55.,27.,13.,13.],
				"l_kern":[11.,5.,3.,3.,3.]}
elif config_setting['pick_layers'] == 1:
	layers = {	"f_in": [3],
				"f_out":[96],
				"l_img":[224],
				"l_kern":[11]}


resources = {"bw":	5e9/bytePerWord/clkRate,		# unit: complex words per cycle
			"alm":	234720,
			"mem":	6.5e6/bytePerWord}				# unit: complex words
consumption = {"cpx_mac": 64*3.2}


def target_function_CaP(model_cnn,model_hw,param_algo,M_img,P_mac,q_mac,q_2dfft,q_2difft,q_1dfft,q_1difft,P_fft,P_ifft):
	num_layers = len(model_cnn["conv_layers"])
	t_layers = np.zeros(num_layers)		# store the runtime for each layer
	N_max = param_algo['fft'].max()
	bw = model_hw['bandwidth']/model_hw['clk_rate']/model_hw['byte_per_word']
	for l in range(num_layers):
		f_in  = model_cnn["conv_layers"][l]["f_in"]
		f_out = model_cnn["conv_layers"][l]["f_out"]
		l_img = model_cnn["conv_layers"][l]["l_img"]
		l_kern = model_cnn["conv_layers"][l]["l_kern"]
		N_l = param_algo['fft'][l]
		D_img = M_img 							# problem here: D_img should be in the unit of f_in*N**2
												# omitting this problem for now
		#D_img = min(M_img,f_in*N**2)			# this is ok. just make sure that you let the M holds the entire image
												# if you change this, you should also change the equation for entire layer.
		Q = (f_out/f_in)*(2*D_img/(D_img+f_in*f_out*l_kern**2))	# kernel is complex number
																# factor of 2 in front of D_img, because of loading real number only.
		bottle1 = P_mac*N_max**2/f_in/q_mac
		bottle2 = P_ifft*N_max**2/q_2difft/q_1difft
		bottle3 = P_fft*N_max**2/q_2dfft/q_1dfft*(f_out/f_in)
		bottle4 = bw*Q/(1+Q)		# this should probably be multiplied by 2, considering that kernel is just real numbers.
		#printf("{:5.3f},{:5.3f},{:5.3f},{:5.3f}",bottle1,bottle2,bottle3,bottle4)
		#printf("fft throughput: {:5.3f}/{:5.3f}", M_img/(M_img+f_in*f_out*N**2)*(resources["bw"]-bottle4),resources["bw"])
		B_ifft = np.min([bottle1,bottle2,bottle3,bottle4])
		#printf("layer {}: bottleneck -- {}", l, [bottle1,bottle2,bottle3,bottle4])
		l_img_prime = (l_img+l_kern-1)/(N_l-l_kern+1)*N_l 	# bounded by this, could be lower
		t_layers[l] = f_out*l_img_prime**2/B_ifft
	#printf(t_layers.sum()/1e6)
	return t_layers.sum()

def target_function_OaA(model_cnn,model_hw,param_algo,M_img,P_mac,q_mac,q_2dfft,q_2difft,q_1dfft,q_1difft,P_fft,P_ifft):
	num_layers = len(model_cnn["conv_layers"])
	t_layers = np.zeros(num_layers)		# store the runtime for each layer
	N_max = param_algo['fft'].max()
	bw = model_hw['bandwidth']/model_hw['clk_rate']/model_hw['byte_per_word']
	for l in range(num_layers):
		f_in  = model_cnn["conv_layers"][l]["f_in"]
		f_out = model_cnn["conv_layers"][l]["f_out"]
		l_img = model_cnn["conv_layers"][l]["l_img"]
		l_kern = model_cnn["conv_layers"][l]["l_kern"]
		N_l = param_algo['fft'][l]
		#if M_img < f_in*N**2:
		#	printf("on-chip memory is not sufficient: you have two choices:\n* split f_in\n* reduce N")
		#	return -1
		D_img = min(M_img,f_in*math.ceil(l_img/(N_l-l_kern+1))**2*N_l**2)			# this is ok. just make sure that you let the M holds the entire image
												# if you change this, you should also change the equation for entire layer.
		Q = (f_out/f_in)*(2*D_img/(D_img+f_in*f_out*l_kern**2))	# kernel is complex number
																# factor of two because of loading real number only.
		bottle1 = P_mac*N_max**2/f_in/q_mac
		bottle2 = P_ifft*N_max**2/q_2difft/q_1difft
		bottle3 = P_fft*N_max**2/q_2dfft/q_1dfft*(f_out/f_in)
		bottle4 = bw*Q/(1+Q)		# this should probably be multiplied by 2, considering that kernel is just real numbers.
		#printf("{:5.3f},{:5.3f},{:5.3f},{:5.3f}",bottle1,bottle2,bottle3,bottle4)
		#printf("fft throughput: {:5.3f}/{:5.3f}", M_img/(M_img+f_in*f_out*N**2)*(resources["bw"]-bottle4),resources["bw"])
		B_ifft = np.min([bottle1,bottle2,bottle3,bottle4])
		#printf("layer {}: bottleneck -- {}", l, [bottle1,bottle2,bottle3,bottle4])
		l_img_prime = math.ceil(l_img/(N_l-l_kern+1))*N_l
		t_layers[l] = f_out*l_img_prime**2/B_ifft
		#import pdb;pdb.set_trace()
	#printf(t_layers)
	#printf(t_layers.sum()/1e6)
	return t_layers.sum()


def consumption_mem(param_algo,M_img,P_mac,q_mac,q_2dfft,q_2difft,q_1dfft,q_1difft,P_fft,P_ifft):
	N = param_algo['fft'].max()
	# FFT
	mem1 = P_fft*(2*N/q_2dfft*3*N + N**2)
	mem1_= (2*1*3*N + N**2)	# for kernel. Hacky way
	# MAC
	mem2 = 0
	# IFFT
	mem3 = P_ifft*(2*N/q_2difft*3*N + N**2)
	# buffer
	mem4 = 2*M_img	# double buffering
	mem_sum = mem1 + mem2 + mem3 + mem4 + mem1_
	#printf("consumption mem: {:4.2f}%, {:4.2f}%, {:4.2f}%, {:4.2f}%, Total {:4.2f}%", 
	#	100*mem1/resources['mem'], 100*mem3/resources['mem'], 100*mem4/resources['mem'], 100*mem1_/resources['mem'],100*mem_sum/resources['mem'])
	return mem1 + mem2 + mem3 + mem4 + mem1_

def consumption_alm(param_algo,M_img,P_mac,q_mac,q_2dfft,q_2difft,q_1dfft,q_1difft,P_fft,P_ifft):
	N = param_algo['fft'].max()
	# FFT
	alm1 = 2*(math.log(N,x)-1)*N/q_1dfft*N/q_2dfft*P_fft*consumption["cpx_mac"]
	alm1_= 2*(math.log(N,x)-1)*1*4*P_fft*consumption["cpx_mac"]		# for kernel: hacky way
	# MAC
	alm2 = P_mac*N**2/q_mac*consumption["cpx_mac"]
	# IFFT
	alm3 = 2*(math.log(N,x)-1)*N/q_1difft*N/q_2difft*P_ifft*consumption["cpx_mac"]
	#if P_mac == 1:
	alm_sum = alm1 + alm2 + alm3 + alm1_
	#printf("consumption alm: {:4.2f}%, {:4.2f}%, {:4.2f}%, {:4.2f}%, Total {:4.2f}%",
	#	100*alm1/resources['alm'], 100*alm2/resources['alm'], 100*alm3/resources['alm'], 100*alm1_/resources['alm'],100*alm_sum/resources['alm'])
	return alm1 + alm2 + alm3 + alm1_


def total_OPS(model_cnn):
	num_ops = 0
	for l in model_cnn['conv_layers']:
		num_ops += l['l_img']**2*l['l_kern']**2*l['f_in']*l['f_out']/l['stride']**2
	return num_ops



def DSE_baseline(model_cnn, model_hw, param_algo, type='CaP'):
	if type=='CaP':
		target_function = target_function_CaP
	else:
		target_function = target_function_OaA
	byte_per_word = model_hw['byte_per_word']
	clk_rate = model_hw['clk_rate']
	logic_max = model_hw['logic']
	memory_max = model_hw['memory']/byte_per_word*1e6
	memory_max_2 = model_hw["memory"]/byte_per_word/2*1e6	# double buffer
	memory_min = memory_max_2*0.5
	memory_stride = (memory_max_2-memory_min)/3
	M_img_range = np.arange(memory_min,memory_max_2,memory_stride)	#resources["mem"],800)	# [e5]	one cache line is 16 complex words
	# problematic for P_mac_range
	P_mac_range = np.arange(1,10)#1200/12)				# [e3]	bounded by peak bw of the system (5GB)
	exp_mac_max = np.log(param_algo['fft'].max())/np.log(2)
	q_mac_range = 2**np.arange(exp_mac_max)							# [e1]	N/2, N/4, N/8, N/16
	exp_fft2_max = exp_mac_max
	exp_fft2_min = np.log(param_algo['fft'].max()/param_algo['fft'].min())/np.log(2)
	exp_fft1_max = exp_fft2_max-2										# -2 because of radix-4
	exp_fft1_min = exp_fft2_min
	q_2dfft_range = 2**np.arange(exp_fft2_min,exp_fft2_max)					# [e1]
	q_2difft_range = 2**np.arange(exp_fft2_min,exp_fft2_max)				# [e1]
	q_1dfft_range = 2**np.arange(exp_fft1_min,exp_fft1_max)
	q_1difft_range = 2**np.arange(exp_fft1_min,exp_fft1_max)
	P_fft_range = np.array([1,4])
	P_ifft_range= np.array([1,4])

	prev_opt = float('Inf')
	opt = []
	for i_M_img in M_img_range:
		printf(i_M_img,type=None)
		#if i_M_img%100 == 0:
		#	printf("{}", i_M_img)
		#	printf("current opt:")
		#	printf("{}", opt, type=None)
		#	printf("current opt:")
		#	printf("{}", prev_opt, type=None)
		for i_P_mac in P_mac_range:
			for i_q_mac in q_mac_range:
				for i_q_2dfft in q_2dfft_range:
					for i_q_2difft in q_2difft_range:
						for i_q_1dfft in q_1dfft_range:
							for i_q_1difft in q_1difft_range:
								for i_P_fft in P_fft_range:
									for i_P_ifft in P_ifft_range:
										mem = consumption_mem(param_algo,i_M_img,i_P_mac,i_q_mac,
															i_q_2dfft,i_q_2difft,i_q_1dfft,i_q_1difft,
															i_P_fft,i_P_ifft)
										if mem >= memory_max: continue
										alm = consumption_alm(param_algo,i_M_img,i_P_mac,i_q_mac,
															i_q_2dfft,i_q_2difft,i_q_1dfft,i_q_1difft,
															i_P_fft,i_P_ifft)
										if alm >= logic_max: continue
										cur_performance = target_function(model_cnn,model_hw,param_algo,i_M_img,i_P_mac,i_q_mac,
															i_q_2dfft,i_q_2difft,i_q_1dfft,i_q_1difft,
															i_P_fft,i_P_ifft)
										if cur_performance >= prev_opt: continue
										prev_opt = cur_performance
										opt = [	i_M_img,i_P_mac,i_q_mac,
												i_q_2dfft,i_q_2difft,
												i_q_1dfft,i_q_1difft,
												i_P_fft,i_P_ifft]
	printf("optimal configuration: ")
	printf("{}", opt, type=None)
	latency = cur_performance/(clk_rate*1e6)
	_latency = latency#((type=='CaP') and [0] or [latency])[0]
	#import pdb;pdb.set_trace()
	return {'latency':_latency*1e3,'throughput':total_OPS(model_cnn)/latency/1e9},\
		{'Memory':opt[0],'P_mac':opt[1],'q_mac':opt[2],'q_2dfft':opt[3],'q_2difft':opt[4],
			'q_1dfft':opt[5],'q_1difft':opt[6],'P_fft':opt[7],'P_ifft':opt[8]}





def arch_dse(model_cnn, model_hw, param_algo, type='CaP'):
	performance, params = DSE_baseline(model_cnn,model_hw,param_algo,type=type)
	conf = [param_algo,params['Memory'],params['P_mac'],params['q_mac'],params['q_2dfft'],params['q_2difft'],params['q_1dfft'],params['q_1difft'],params['P_fft'],params['P_ifft']]
	stat_resource = {'logic':consumption_alm(*conf)/model_hw['logic'], 'memory':consumption_mem(*conf)/(model_hw['memory']*1e6/model_hw['byte_per_word'])}
	return performance, params, stat_resource

def min_bw_time():
	data_traffic = 0
	for i in range(len(layers["f_in"])):
		if i == 0 or i == 1:
			N = 64
		else:
			N = 16
		f_in = layers["f_in"][i]
		f_out = layers['f_out'][i]
		l_img = layers['l_img'][i]
		l_kern = layers['l_kern'][i]
		data_traffic += f_in*f_out*l_kern**2/2 + (f_in/2+f_out)*math.ceil((l_img+l_kern-1)/(N-l_kern+1))**2*N**2
	return data_traffic/resources['bw']/clkRate*1000		# unit of ms

if __name__ == "__main__":
	#printf(min_bw_time())
	#exit()
	#DSE_baseline()
	#M_img,P_mac,q_mac,q_2dfft,q_2difft,q_1dfft,q_1difft,P_fft,P_ifft
	#conf = [0.5e6,1,4,64,32,16,16,1,1]
	conf = [0.5e6,4,1,16,8,4,4,1,1]
	#target_function(*conf)
	#consumption_alm(*conf)
	#consumption_mem(*conf)
	#layers = {"f_in":[256],"f_out":[384],"l_img":[],"l_kern":[]}
	target_function_OaA(*conf)
	#target_function_CaP(*conf)
	consumption_alm(*conf)
	consumption_mem(*conf)