"""
FORMAT:
    %d %d %d %d - %d
    4 input values - valid_in
"""

from zython.logf.filef import print_to_file
import numpy as np

def gen_spn_tb_input(N,p):
    n = N**2
    f_name = 'input_file.txt'
    data = np.arange(n).reshape(-1,p)
    str_ip = '0 0 0 0 - 0\n'
    valid_in = np.array([1]*data.shape[0])
    #valid_in[-1] = 0
    for i,input_stream in enumerate(data):
        str_list = [str(ip) for ip in input_stream]
        str_ip += ' '.join(str_list)
        str_ip += ' - {}\n'.format(valid_in[i])
    print_to_file(f_name,str_ip,type=None,log_dir='.',mode='w')


if __name__ == "__main__":
    gen_spn_tb_input(16,4)
