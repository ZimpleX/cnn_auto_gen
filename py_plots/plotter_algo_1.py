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

# param list: [fin, fout, l_img, l_kern, N, stride, padding]
layers = 	 [[  3,   96,   224,     11,64,      4,       0],
			  [ 96,  256,    55,      5,64,      1,       2],
		      [256,  384,    27,      3,64,      1,       1],
			  [384,  384,    13,      3,64,      1,       1],
			  [384,  256,    13,      3,64,      1,       1]]
"""
layers =   [[  3, 64,224,3,1,1],
			[ 64,128,224,3,1,1],
			[128,128,112,3,1,1],
			[128,256,112,3,1,1],
			[256,256, 56,3,1,1],
			[256,256, 56,3,1,1],
			[256,512, 28,3,1,1],
			[512,512, 28,3,1,1],
			[512,512, 28,3,1,1],
			[512,512, 14,3,1,1],
			[512,512, 14,3,1,1],
			[512,512, 14,3,1,1],
			[512,512, 14,3,1,1]]
"""

def plot_fixed_len_FFT():
	bars = {16: [], 32:[], 64:[], 128:[]}
	for FFT_fixed in list(bars.keys()):
		for i,layer in enumerate(layers):
			layer[4] = FFT_fixed
			_op_oaa = op.op_count_fft(*layer)/1e9
			bars[FFT_fixed] += [_op_oaa]

	lines = {"spatial":[], "var_fft":[], "native_fft":[]}
	for i,layer in enumerate(layers):
		_op_spatial = op.op_count_spatial(*layer)/1e9
		lines["spatial"] += [_op_spatial]
	layers[0][4] = 32	# 32: OaA
	layers[1][4] = 16	# 16: OaA
	layers[2][4] = 32	# 32: Native
	layers[3][4] = 16	# 16: Native
	layers[4][4] = 16	# 16: Native
	lines["var_fft"] += [op.op_count_fft(*layers[0])/1e9]
	lines["var_fft"] += [op.op_count_fft(*layers[1])/1e9]
	lines["var_fft"] += [op.op_count_fft(*layers[2])/1e9]
	lines["var_fft"] += [op.op_count_fft(*layers[3])/1e9]
	lines["var_fft"] += [op.op_count_fft(*layers[4])/1e9]
	#import pdb;pdb.set_trace()

	conv_layers = np.arange(len(layers))+1
	fig1 = plt.figure(1)
	ax = plt.subplot(111)
	ax.set_aspect(0.6)
	#ax.set_title("Effect of variable length FFT", fontsize=20)
	ax.set_xlabel("Convolution layers", fontsize=16)
	ax.set_ylabel("Giga Operations", fontsize=16)
	ax.set_ylim([0,4.8])
	ax.set_xlim([0.5,5.5])

	box = ax.get_position()
	ax.set_position([box.x0,box.y0,box.width*0.8,box.height])

	ax.xaxis.set_major_locator(MaxNLocator(integer=True))
	line_spatial, = ax.plot(conv_layers, lines["spatial"],'-o',label='Spatial')
	line_var_fft, = ax.plot(conv_layers, lines["var_fft"],'--^',label='FFT-hybd',color='G',markersize=10,linewidth=2)

	cmap = plt.get_cmap("autumn")#.cm.gist_ncar
	colors = [cmap(i) for i in np.linspace(0,1,len(layers))]
	bar_width = 0.1
	for i,FFT_fixed in enumerate(sorted(list(bars.keys()))):
		ax.bar(conv_layers+bar_width*(i-2), bars[FFT_fixed], bar_width, color=colors[i],label='OaA-{}'.format(FFT_fixed),edgecolor="none")

	ax.legend(loc='center left', bbox_to_anchor=(1,0.5),fancybox=True,shadow=True,ncol=1)
	#plt.show()
	plt.savefig("plots/algo_I.pdf",bbox_inches='tight')

	_op_spatial_tot = sum(lines['spatial'])
	for K in list(bars.keys()):
		printf("[FFT-{}]: {}, {}x",K,sum(bars[K]),_op_spatial_tot/sum(bars[K]))
	printf("[FFT-hybd]: {}, {}x", sum(lines["var_fft"]),_op_spatial_tot/sum(lines["var_fft"]))


if __name__ == "__main__":
	plot_fixed_len_FFT()
