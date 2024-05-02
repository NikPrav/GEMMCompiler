import torch
import torch.nn as nn
from torch.autograd import Variable
import fpga
import numpy as np

from memory_handler import DRAM
from layer_nodes import LayerNode
from compiler import GEMMCompiler, SystolicArrayParams
from padding import padding_func, padding_func_ip

# import chain
from itertools import chain

# x = Variable(torch.randn(1,7,7, dtype=torch.float16))

x = torch.tensor([[1,2,3,4,5,6],[7,8,9,10,11,12],[13,14,15,16,17,18]], dtype=torch.float16)
input = x

print(f"Input array:\n {x}")

# Initialize an empty list to store the layer info objects
node_list = []

# Create the model
# model = nn.Sequential(nn.Linear(7, 10, dtype=torch.float16, bias=False), nn.Linear(10, 5, dtype=torch.float16, bias=False))
model = nn.Sequential(nn.Linear(6, 3, dtype=torch.float16, bias=False))



# Setting Systolic Array Parameters
R, C = 4, 4  # Size of the systolic array
mem_size = 1024*16  # Memory size of the FPGA
data_size = 16
i_buf_size = 16*data_size  # Input buffer size of the FPGA
w_buf_size = i_buf_size  # Weight buffer size of the FPGA
o_buf_size = R*C*data_size  # Output buffer size of the FPGA

print(f"Systolic array parameters: \n R: {R}, \n C: {C}, \n Memory size: {mem_size//8}B, \n Data size: {data_size} bits, \n Input buffer size: {i_buf_size//8}B, \n Weight buffer size: {w_buf_size//8}B, \n Output buffer size: {o_buf_size//8}B")

sys_params = SystolicArrayParams(R, C, mem_size, i_buf_size, w_buf_size, o_buf_size, data_size)

model[0].weight = nn.Parameter(data=torch.tensor([[1,2,3,4,5,6],[7,8,9,10,11,12],[13,14,15,16,17,18]], dtype=torch.float16))

print(f"Weight array: \n {model[0].weight}")

output = model(x)
print(f"Expected output array: \n {output}")
# model[1].weight = nn.Parameter(data=torch.tensor([[1,2,3],[5,6,7],[9,10,11], [13,14,15]], dtype=torch.float16))
# model[0].bias = nn.Parameter(data=torch.tensor([0,0,0,0,0,0,0,0,0,0], dtype=torch.float16))
# model[1].bias = nn.Parameter(data=torch.tensor([0,0,0,0,0], dtype=torch.float16))

# Loop through each layer in the model and padding
for name, layer in model.named_children():
    if isinstance(layer, torch.nn.modules.conv.Conv2d) or isinstance(layer, torch.nn.modules.linear.Linear):
        new_node = LayerNode(name,layer, x)
        padded_node = padding_func(new_node,sys_params)
        node_list.append(padded_node)
        x = layer(x)


# Create 1D DRAM array representation with instructions and memory
Dram_content = DRAM(mem_size, sys_params)
w_ptr_end = Dram_content.mem_init(node_list, sys_params)

input = padding_func_ip(input, sys_params)

Dram_content.flash_inputs(input.T.flatten().detach().numpy(), w_ptr_end)

i_ptr_cur = w_ptr_end
w_ptr_cur = sys_params.inst_mem

instruction_list = []
instruction_list_test = []
instruction_num = 0

op_ptr = 0

for node in node_list:
    M = node.input_size[-2]
    N = node.input_size[-1]
    K = node.weight_size[-2]

    gemm = GEMMCompiler(M, N, K, sys_params, i_ptr_cur, w_ptr_cur, w_ptr_end)
    o_ptr = i_ptr_cur
    instructions, i_ptr_cur, instructions_test = gemm.compile_matrices() 
    instruction_list.append(np.array(instructions))
    instruction_list_test.append(instructions_test)
    w_ptr_cur = w_ptr_cur + node.weight_size[0]*node.weight_size[1]*sys_params.data_size
    
layer_num = 0
for i in instruction_list:
    Dram_content.instructions[(instruction_num):(len(instruction_list[layer_num])+instruction_num)] = np.array(i)
    instruction_num+=len(instruction_list[layer_num])
    layer_num += 1
    
Dram_content.generate_lists(instruction_list)


# Create FPGA
fpga_test = fpga.FPGA(sys_params, Dram_content, M*sys_params.data_size, K*sys_params.data_size)
# print(instruction_list_test)
fpga_test.flash(instruction_list_test)

fpga_test.execute(list(chain.from_iterable(instruction_list_test)))

# Add code to run verilog

# Read back the text file
# Dram_content.parse_generated_data("filename.txt")


print(f"Output from FPGA:\n {fpga_test.extract(i_ptr_cur-sys_params.inst_mem, (M,K))}")
