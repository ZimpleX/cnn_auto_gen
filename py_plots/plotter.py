import math
import matplotlib.pyplot as plt
from matplotlib.pyplot import cm
from mpl_toolkits.mplot3d import Axes3D
from matplotlib.ticker import LinearLocator, FormatStrFormatter

import numpy as np
from zython.logf.printf import printf
import zython.logf.filef as filef

import py_util.op_calculation as op


def plot_fft_size_folding(f_in,f_out,l_img,l_kern,range_N=None,range_folding=None, name=''):
	"""
	3D plotter
	"""
	N_min_power = 1
	N_max_power = 4
	folding_min = 1
	folding_max = 10
	title = '{}_N_{}_{}_fd_{}_{}'.format(name,N_min_power,N_max_power,folding_min,folding_max)
	range_N = range_N and range_N or 4**np.arange(N_min_power,N_max_power+1)
	range_folding = range_folding and range_folding or np.arange(folding_min,folding_max+1)
	dots = np.zeros((3,len(range_N),len(range_folding)))
	X = range_N
	Y = range_folding
	X,Y = np.meshgrid(X,Y)
	Z = op.op_count_fft(f_in,f_out,l_img,l_kern,X,None,None,folding_1D=Y)/1e6

	#import pdb; pdb.set_trace()
	# the plot won't contain invalid data unless N is too small (smaller than l_kern)
	fig = plt.figure()
	ax = fig.gca(projection='3d')

	surf = ax.plot_surface(X,Y,Z, cmap=cm.coolwarm, rstride=1,cstride=1, linewidth=0, antialiased=False)
	ax.set_zlim(Z.min(),0.5*Z.max())
	#ax.zaxis.set_major_locator(LinearLocator(10))
	#ax.zaxis.set_major_formatter(FormatStrFormatter('%.02f'))
	fig.colorbar(surf, shrink=0.5, aspect=5)

	ax.set_xlabel('FFT size')
	ax.set_ylabel('folding')
	ax.set_zlabel('# ops')
	#plt.show()
	plt.savefig('plots/{}.png'.format(title))
	Z[Z==0.] = float('Inf')
	min_args = np.unravel_index(Z.argmin(),Z.shape)
	return X[min_args],Y[min_args]
	#return min_args

def ceiling_inverse():
	x = np.arange(4,111)
	k = 1000
	y = np.log(x)*x**2*np.ceil(k/(x-1)**2)
	plt.plot(x,y,'o')
	plt.show()


if __name__ == '__main__':
	#ceiling_inverse()
	layers = [[  3, 96,224,11],
			  [ 96,256, 55, 5],
			  [256,384, 27, 3],
			  [384,384, 13, 3],
			  [384,384, 13, 3]]
	printf('optimal values:')
	printf('   layer       N folding',type=None, separator='-')
	for i,l in enumerate(layers):
		N_i, fd_i = plot_fft_size_folding(*l, name='layer{}'.format(i))
		printf('{:8d}{:8d}{:8d}',i,N_i,fd_i,type=None,separator=None)
