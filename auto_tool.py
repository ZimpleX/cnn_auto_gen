import argparse
from zython.logf.printf import printf
import numpy as np
import yaml
import py_dse.algo_design_space_explore as algo_dse
import py_dse.arch_design_space_explore as arch_dse

"""
CaP will surely reduce the complexity of OaA.
But, the biggest benefit I think is the MODULARITY in hardware.
You can run multiple CNNs -- arbitrary layers on the same FPGA,
without the need of any reconfiguration. 
--> the only thing to keep track of is f_in,f_out for MAC.
--> this information is in the CNN itself. 
--> User won't need to provide any additional information.
"""


def parse_args():
	parser = argparse.ArgumentParser('FFT CNN design auto generation')
	parser.add_argument('-n','--cnn', type=str,required=True, 
			help='path to the cnn config *.yaml file')
	parser.add_argument('-p','--hardware', type=str,required=True,
			help='path to the hardware config *.yaml file')
	parser.add_argument('--cap', action='store_true',default=False)
	return parser.parse_args()

def go(args):
	model_cnn = yaml.load(open(args.cnn))
	model_hw = yaml.load(open(args.hardware))
	#########################
	# algo level optimization
	#########################
	# OPS: {'tool': [x1,x1], 'spatial': [y1,y2]}
	# param_algo: {'fft': [N1,N2], 'folding': [f1,f2]}
	OPS, param_algo = algo_dse.algo_dse(model_cnn, model_hw,options={'CaP':args.cap,'max_folding':0,'var_fft':True})
	#########################
	# arch level optimization
	#########################
	# performance: {'latency': [l1,l2], 'throughput': [t1,t2]}
	# param_arch: {''}
	arch_type = (args.cap) and 'CaP' or 'OaA'
	performance, param_arch, stat_resource = arch_dse.arch_dse(model_cnn, model_hw, param_algo,type=arch_type)

	printf('algo params: {}', param_algo)
	printf('operation count: {:5.4f}%', OPS['tool'].sum()/OPS['spatial'].sum())
	printf('latency: {:5.2f}ms throughput: {:5.1f}GOPS', performance['latency'],performance['throughput'])
	printf('arch params: {}', param_arch)
	printf('utilization: {}', stat_resource)
	#printf('performance: {}', performance)


if __name__ == '__main__':
	args = parse_args()
	go(args)