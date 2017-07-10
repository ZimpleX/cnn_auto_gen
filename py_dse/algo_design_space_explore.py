import numpy as np
from zython.logf.printf import printf
import zython.logf.filef as filef
import zython.arithmetic as arizhmetic
import py_util.op_calculation as op



def optimize_throughput(f_in,f_out,l_img,l_kern,available_FFT):
	ops_CaP,config_CaP = op.operation_min_CaP(f_in,f_out,l_img,l_kern,available_FFT)
	ops_OaA,config_OaA = op.operation_min_OaA(f_in,f_out,l_img,l_kern,available_FFT)
	ops_min = np.concatenate([ops_CaP.reshape(1,-1),ops_OaA.reshape(1,-1)],axis=0)
	argmin = np.argmin(ops_min,axis=0)
	num_layers = len(ops_CaP)
	ops_min = ops_min[argmin,np.arange(num_layers)]
	config_N = np.concatenate([config_CaP[0].reshape(1,-1),config_OaA[0].reshape(1,-1)],axis=0)
	config_fd = np.concatenate([config_CaP[1].reshape(1,-1),config_OaA[1].reshape(1,-1)],axis=0)
	config_N = config_N[argmin,np.arange(num_layers)]
	config_fd = config_fd[argmin,np.arange(num_layers)]
	return ops_min,config_N,config_fd

def optimize_latency(f_in,f_out,l_img,l_kern,available_FFT):
	ops_OaA,config_OaA = op.operation_min_OaA(f_in,f_out,l_img,l_kern,available_FFT)
	return ops_OaA,config_OaA[0],config_OaA[1]



def algo_dse(model_cnn, model_hw, options={'CaP': True, 'max_folding': 0, 'var_fft': True}):
	# CNN parameters
	conv_layers = model_cnn['conv_layers']
	l_img = np.array([l['l_img'] for l in conv_layers])
	l_kern = np.array([l['l_kern'] for l in conv_layers])
	f_in = np.array([l['f_in'] for l in conv_layers])
	f_out = np.array([l['f_out'] for l in conv_layers])
	stride = np.array([l['stride'] for l in conv_layers])
	# FPGA parameters
	available_FFT = np.array(model_hw['available_FFT'])
	# baseline
	ops_spatial = op.op_count_spatial(f_in,f_out,l_img,l_kern,stride,padding=l_kern-1)
	if options['CaP']:
		ops_tool,config_N,config_fd = optimize_throughput(f_in,f_out,l_img,l_kern,available_FFT)
	elif options['var_fft']:
		ops_tool,config_N,config_fd = optimize_latency(f_in,f_out,l_img,l_kern,available_FFT)
	return {'tool':ops_tool,'spatial':ops_spatial}, {'fft':config_N,'folding':config_fd}




def core_fft_size_folding(f_in,f_out,l_img,l_kern,range_N=None,range_folding=None, name=''):
	"""
	design space explore (brute force) on a given CNN layer.
	this function gives the optimal cnfiguration of FFT size and folding factor for each layer.
	"""
	N_min_power = 1
	N_max_power = 8
	folding_min = 1
	folding_max = 20
	range_N = ((range_N is not None) and [np.array(range_N)] or [4**np.arange(N_min_power,N_max_power+1)])[0]
	range_folding = ((range_folding is not None) and [np.array(range_folding)] or [np.arange(folding_min,folding_max+1)])[0]
	range_N, range_folding = np.meshgrid(range_N, range_folding)
	range_ops = op.op_count_fft(f_in, f_out, l_img, l_kern, range_N, None, None, folding_1D=range_folding) / 1e6

	range_ops[range_ops == 0.] = float('Inf')
	min_args = np.unravel_index(range_ops.argmin(), range_ops.shape)
	return range_ops.min(), range_N[min_args], range_folding[min_args]

def explore_fix_folding(layers,range_N=None,range_folding=None, name=''):
	"""
	will give the full statistics for each fixed folding factor.
	"""
	N_min_power = 2
	N_max_power = 2
	folding_min = 1
	folding_max = 30
	range_N = ((range_N is not None) and [np.array(range_N)] or [[16,32]])[0]#[4**np.arange(N_min_power,N_max_power+1)])[0]
	range_folding = ((range_folding is not None) and [np.array(range_folding)] or [np.arange(folding_min,folding_max+1)])[0]
	min_ops_layers = np.zeros((len(range_folding),len(layers)))
	ops_spatial_layers = np.zeros(len(layers))
	for i_l,l in enumerate(layers):
		ops_spatial_layers[i_l] = op.op_count_spatial(*(l[0:4]),None,*(l[4:6]))/1e6
	ops_spatial_total = ops_spatial_layers.sum()
	N_layers = np.zeros((len(range_folding),len(layers)))
	for i_fd,fd in enumerate(range_folding):
		printf('optimal values (FFT,folding={}):',fd)
		printf('   layer       N folding      MinOps   ratio',type=None, separator='-')
		for i_l,l in enumerate(layers):
			min_ops_layers[i_fd][i_l], N_layers[i_fd][i_l], fd_i = core_fft_size_folding(*(l[0:4]),range_N=range_N,range_folding=fd,name='')
			printf('{:8d}{:8d}{:8d}{:12.2f}{:8.3f}',i_l+1,int(N_layers[i_fd][i_l]),fd_i,min_ops_layers[i_fd][i_l],
				   min_ops_layers[i_fd][i_l]/ops_spatial_layers[i_l], type=None,separator=None)
		min_ops_sum = min_ops_layers[i_fd].sum()
		printf("Total ops: {:12.2f}; ratio: {:5.3f}",min_ops_sum,min_ops_sum/ops_spatial_total,type=None,separator='><')
	idx_folding = np.sum(min_ops_layers,axis=1).argmin()
	return N_layers[idx_folding],range_folding[idx_folding],np.sum(min_ops_layers,axis=1).min()



if __name__ == '__main__':
	#printf('optimal values (FFT,folding):')
	#printf('   layer       N folding      MinOps',type=None, separator='-')
	#min_ops_layers = np.zeros(len(layers))
	#for i,l in enumerate(layers):
	#	min_ops_layers[i], N_i, fd_i = core_fft_size_folding(*(l[0:4]), name='vgg16_layer{}'.format(i))
	#	printf('{:8d}{:8d}{:8d}{:12.2f}',i+1,N_i,fd_i,min_ops_layers[i],type=None,separator=None)
	#printf("Total ops: {:12.2f}",min_ops_layers.sum(),type=None,separator='><')

	explore_fix_folding(layers,name='vgg16')
