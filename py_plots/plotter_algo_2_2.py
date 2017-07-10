import py_util.op_calculation as op
import numpy as np
from zython.logf.printf import printf
import zython.logf.filef as filef
import math
import matplotlib.pyplot as plt
from matplotlib.pyplot import cm
from matplotlib.ticker import MaxNLocator

from matplotlib import rc

from matplotlib.colors import ListedColormap

rc('font',**{'family':'serif','serif':['Times']})
rc('text', usetex=True)


def compare_three_opts(N,l_img,l_kern):
	"""
	input: all numbers, not array;
	output: 1 for choosing native;
			2 for choosing OaA;
			3 for choosing CaP-OaA.
	"""
	K = (l_img+l_kern-1)/(N-l_kern+1)
	spd_OaA = math.ceil(K)/K
	if N >= (l_img + l_kern - 1):
		spd_native = (1/K)**2
	else:
		spd_native = float('Inf')
	if spd_native < spd_OaA:	# native approach is better
		if spd_native <= 1.02:
			return 11
		else:
			return 13
	else:
		if spd_OaA < 1.02:
			return 12
		else:
			return 13

def plot():
	l_kern = 9
	N_range = np.arange(16,220,2)
	l_img_range = np.arange(16,220,2)
	approach_grid = np.zeros((l_img_range.size, N_range.size))
	for x,N in enumerate(N_range):
		for y,l_img in enumerate(l_img_range):
			approach_grid[y][x] = compare_three_opts(N,l_img,l_kern)
	#cmap = plt.get_cmap("autumn")#.cm.gist_ncar
	#colors = [cmap(i) for i in np.linspace(0.5,1,len(layers))]
	"""
	plt.axes().set_aspect('equal','datalim')
	plt.axes().set_xlabel("FFT Size")
	plt.axes().set_ylabel("Image Size")
	#plt.axes().get_xaxis().set_visible(False)
	#plt.axes().get_yaxis().set_visible(False)
	plt.axis('off')
	#plt.set_xlim([0,220])
	heatmap = plt.pcolor(approach_grid,cmap=plt.get_cmap('Blues'))
	#import pdb; pdb.set_trace()
	printf("unique values: {}", np.unique(approach_grid))
	cbar = plt.colorbar(heatmap)
	plt.savefig("./plots/algo_II_2.pdf", bbox_inches='tight')
	"""
	fig,ax = plt.subplots()
	cmap = plt.get_cmap('Blues')
	cMap = ListedColormap([cmap(i) for i in np.linspace(0.4,1,3)])
	#import pdb; pdb.set_trace()
	heatmap = ax.pcolor(approach_grid,cmap=cMap)
	cbar = plt.colorbar(heatmap)
	cbar.ax.get_yaxis().set_ticks([])
	for j,lab in enumerate(['Native','OaA','CaP-OaA']):
		cbar.ax.text(1,(2*j+1)/8, lab, ha='center',va='center')
	cbar.ax.get_yaxis().labelpad = 15
	#cbar.ax.set_ylabel('')

	ax.set_xticks(np.arange(approach_grid.shape[1]/20)+0.5, minor=False)
	ax.set_yticks(np.arange(approach_grid.shape[0])+0.5, minor=False)
	ax.invert_yaxis()

	col_lab = [20,60,100,140,180,220]
	row_lab = [20,60,100,140,180,220]

	ax.set_xticklabels(col_lab, minor=False)
	ax.set_yticklabels(row_lab, minor=False)

	plt.savefig('./plots/algo_II_2.pdf', bbox_inches='tight')


if __name__ == "__main__":
	plot()
