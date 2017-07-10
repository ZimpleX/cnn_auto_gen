import py_util.op_calculation as op
import numpy as np
from zython.logf.printf import printf
import zython.logf.filef as filef
import math
import matplotlib.pyplot as plt
from matplotlib.pyplot import cm
from matplotlib.ticker import MaxNLocator

from matplotlib import rc

rc('font',**{'family':'serif','serif':['Times']})
rc('text', usetex=True)

layers = 	 [[  3,   96,   224,     11,16,      4,       0],
			  [ 96,  256,    55,      5,16,      1,       2],
		      [256,  384,    27,      3,16,      1,       1],
			  [384,  384,    13,      3,16,      1,       1],
			  [384,  256,    13,      3,16,      1,       1]]

#layers =   [[  3, 64,224,3,32,1,1],
#			[ 64,128,224,3,32,1,1],
#			[128,128,112,3,32,1,1],
#			[128,256,112,3,32,1,1],
#			[256,256, 56,3,32,1,1],
#			[256,256, 56,3,32,1,1],
#			[256,512, 28,3,32,1,1],
#			[512,512, 28,3,32,1,1],
#			[512,512, 28,3,32,1,1],
#			[512,512, 14,3,16,1,1],
#			[512,512, 14,3,16,1,1],
#			[512,512, 14,3,16,1,1],
#			[512,512, 14,3,16,1,1]]
def stat_FFT_CaP_OaA(f_in,f_out,l_img,l_kern,available_FFT):
	return op.operation_min_OaA(f_in,f_out,l_img,l_kern,available_FFT)[0],\
			op.operation_min_CaP(f_in,f_out,l_img,l_kern,available_FFT)[0]



def stat_FFT_hybrid(N,l_img, l_kern):
	"""
	l_img_pad = l_img + l_kern -1
	N: 1D array;
	l_kern: single data
	l_img_pad: 1D array.
	output: 1D array of size l_img_pad.
	"""
	l_img_pad = np.array(l_img).flatten()
	N = np.array(N).flatten()
	out_native = np.zeros(l_img.shape)
	out_OaA = np.zeros(l_img.shape)
	out_CaP_OaA = np.zeros(l_img.shape)
	out_hyb_native_OaA = np.zeros(l_img.shape)
	out_native[:] = float('Inf')
	out_OaA[:] = float('Inf')
	out_CaP_OaA[:] = float('Inf')
	out_hyb_native_OaA[:] = float('Inf')
	for i,l in enumerate(l_img):
		for n in N:
			# native FFT
			if n >= l + l_kern - 1:
				if n**2 < out_native[i]:
					out_native[i] = n**2
				if n**2 < out_hyb_native_OaA[i]:
					out_hyb_native_OaA[i] = n**2
			# OaA
			_temp = (math.ceil(l/(n-l_kern+1))*n)**2
			if _temp < out_OaA[i]:
				out_OaA[i] = _temp
			if _temp < out_hyb_native_OaA[i]:
				out_hyb_native_OaA[i] = _temp
			# CaP
			K = (l + l_kern - 1)/(n - l_kern + 1)
			_temp = (K*n)**2
			if _temp < out_CaP_OaA[i]:
				out_CaP_OaA[i] = _temp
	return out_native, out_OaA, out_CaP_OaA, out_hyb_native_OaA


def complexity_CaP(layer):
	K = (layer[3] + layer[2] - 1)/(layer[4]-layer[3]+1)
	folding_opt = (layer[4]-layer[3]+1)/math.gcd(layer[2]+layer[3]-1, layer[4]-layer[3]+1)
	complexity = op.op_count_fft(*layer,folding_1D=folding_opt)
	return complexity, folding_opt


def compare_CaP_OaA():
	printf("  hybd1 complexity | CaP complexity | folding | spatial complexity", type=None)
	sum_complexity1 = 0
	sum_complexity2 = 0
	sum_baseline = 0
	for layer in layers:
		complexity_baseline = op.op_count_spatial(*layer)
		complexity1 = op.op_count_fft(*layer,folding_1D=1)
		layer[4] = 16
		complexity2, folding_opt = complexity_CaP(layer)
		sum_complexity1 += complexity1
		sum_complexity2 += complexity2
		sum_baseline += complexity_baseline
		printf("{} | {} | {} | {}", complexity1/1e9, complexity2/1e9, folding_opt, complexity_baseline/1e9, type=None)
	printf("sum: hybd1 vs. CaP vs. spatial")
	printf("{} ({}) {} ({}) {}",sum_complexity1/1e9, sum_complexity1/sum_baseline, sum_complexity2/1e9, sum_complexity2/sum_baseline,sum_baseline)



def plot():
	rc('xtick', labelsize=8)
	rc('ytick', labelsize=8)
	N1 = np.array([8,16,32,64])
	N2 = np.array([16,64])
	l_img = np.arange(10,224,1)
	num_images = len(l_img)
	l_kern = np.array([3]*num_images)
	f_in = np.array([100]*num_images)
	f_out = np.array([200]*num_images)
	#out_native1, out_OaA1, out_CaP_OaA1, out_hyb_native_OaA1 = stat_FFT_hybrid(N1,l_img,l_kern)
	#out_native2, out_OaA2, out_CaP_OaA2, out_hyb_native_OaA2 = stat_FFT_hybrid(N2,l_img,l_kern)
	out_hyb_native_OaA1,out_CaP_OaA1 = stat_FFT_CaP_OaA(f_in,f_out,l_img,l_kern,N1)
	out_hyb_native_OaA2,out_CaP_OaA2 = stat_FFT_CaP_OaA(f_in,f_out,l_img,l_kern,N2)

	fig1 = plt.figure(1)

	ax = plt.subplot(111)
	ax.set_aspect(85)
	ax.set_xlabel("Image Size", fontsize=8)
	ax.set_ylabel("Reduction in Computation Complexity by CaP", fontsize=8)

	box = ax.get_position()
	#ax.set_position([box.x0,box.y0,box.width*0.8,box.height])

	ax.xaxis.set_major_locator(MaxNLocator(integer=True))
	points_speedup1, = ax.plot(l_img, out_CaP_OaA1/out_hyb_native_OaA1,'ro',label='FFT Seq 1',markersize=3.5)
	points_speedup2, = ax.plot(l_img, out_CaP_OaA2/out_hyb_native_OaA2,'bx',label='FFT Seq 2',markersize=4.5)
	points_ref, = ax.plot(l_img,l_img*0+1, 'g--')
	points_ref_1, = ax.plot(l_img,l_img*0+0.8, 'g--')

	#ax = plt.subplot(212)
	#ax.set_aspect(4)
	#ax.set_xlabel("Image size", fontsize=12)
	#ax.set_ylabel("Speedup", fontsize=12)
	#box = ax.get_position()
	#ax.set_position([box.x0,box.y0,box.width*0.8,box.height])

	#ax.xaxis.set_major_locator(MaxNLocator(integer=True))

	#points_speedup_native = ax.plot(l_img, out_native/out_CaP_OaA, 'ro', label='Native',markersize=3.5)
	#points_speedup_OaA = ax.plot(l_img, out_OaA/out_CaP_OaA, 'bx', label='OaA',markersize=3.5)
	#import pdb; pdb.set_trace()
	#cmap = plt.get_cmap("autumn")#.cm.gist_ncar
	#colors = [cmap(i) for i in np.linspace(0,1,len(layers))]
	"""
	#N = np.array([4,8,16,32,64,128,256])
	out_native, out_OaA, out_CaP_OaA = stat_FFT_hybrid(N,l_img,l_kern)
	l_kern = 5
	ax = plt.subplot(212)
	ax.set_aspect(0.6)
	ax.set_xlabel("", fontsize=16)
	ax.set_ylabel("", fontsize=16)

	box = ax.get_position()
	ax.set_position([box.x0,box.y0,box.width*0.8,box.height])

	ax.xaxis.set_major_locator(MaxNLocator(integer=True))
	points_native, = ax.plot(l_img, out_native/1e3,'ro',label='native',markersize=4)
	points_OaA, = ax.plot(l_img, out_OaA/1e3, 'bx', label='OaA',markersize=4)
	points_CaP_OaA = ax.plot(l_img, out_CaP_OaA/1e3, 'g^', label='CaP-OaA',markersize=4)
	#import pdb; pdb.set_trace()
	cmap = plt.get_cmap("autumn")#.cm.gist_ncar
	#colors = [cmap(i) for i in np.linspace(0,1,len(layers))]
	"""

	#ax.legend(loc='center left', bbox_to_anchor=(1,0.5),fancybox=True,shadow=True,ncol=1)
	ax.legend(fontsize=8,loc=4)

	plt.savefig("plots/algo_II_correct_1.pdf",bbox_inches='tight')

	#for i,l in enumerate(l_img):
	#	printf("img: {} -- [Native]: {}, [OaA]: {}, [CaP-OaA]: {}", l+l_kern-1, out_native[i],out_OaA[i],out_CaP_OaA[i])


if __name__ == "__main__":
	plot()
	#compare_CaP_OaA()
