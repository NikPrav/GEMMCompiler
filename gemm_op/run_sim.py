import torch
import torch.nn as nn
from torch.autograd import Variable
import fpga

from memory_handler import DRAM
from layer_nodes import LayerNode
from compiler import GEMMCompiler, SystolicArrayParams
from padding import padding_func, padding_func_ip

# import chain
from itertools import chain

# x = Variable(torch.randn(1,7,7))

x = torch.tensor([[1,2,3,4,5,6],[7,8,9,10,11,12],[13,14,15,16,17,18]], dtype=torch.int16)
input = x

# Initialize an empty list to store the layer info objects
node_list = []

# Create the model
model = nn.Sequential(nn.Linear(6, 4, dtype=torch.int16), nn.Linear(4, 4, dtype=torch.int16))

output = model(x)
print(output.size())

# Setting Systolic Array Parameters
R, C = 2, 2  # Size of the systolic array
mem_size = 1096*1096  # Memory size of the FPGA
data_size = 16
i_buf_size = 16*data_size  # Input buffer size of the FPGA
w_buf_size = i_buf_size  # Weight buffer size of the FPGA
o_buf_size = R*C*data_size  # Output buffer size of the FPGA

sys_params = SystolicArrayParams(R, C, mem_size, i_buf_size, w_buf_size, o_buf_size, data_size)

model[0].weight = nn.Parameter(data=torch.tensor([[1,2,3,4,5,6],[7,8,9,10,11,12],[13,14,15,16,17,18], [19, 20, 21, 22, 23, 24]], dtype=torch.int16))
model[1].weight = nn.Parameter(data=torch.tensor([[1,2,3,4],[5,6,7,8],[9,10,11,12], [13,14,15,16]], dtype=torch.int16))


# Loop through each layer in the model and padding
for name, layer in model.named_children():
    if isinstance(layer, torch.nn.modules.conv.Conv2d) or isinstance(layer, torch.nn.modules.linear.Linear):
        new_node = LayerNode(name,layer, x)
        padded_node = padding_func(new_node,sys_params)
        node_list.append(padded_node)
        x = layer(x)


# Create 1D DRAM array representation with instructions and memory
Dram_content = DRAM(mem_size)
w_ptr_end = Dram_content.mem_init(node_list, sys_params)

input = padding_func_ip(input, sys_params)

Dram_content.flash_inputs(input.T.flatten().detach().numpy(), w_ptr_end)

i_ptr_cur = w_ptr_end
w_ptr_cur = sys_params.inst_mem

instruction_list = []
instruction_list_test = []

op_ptr = 0

for node in node_list:
    M = node.input_size[-2]
    N = node.input_size[-1]
    K = node.weight_size[-2]

    gemm = GEMMCompiler(M, N, K, sys_params, i_ptr_cur, w_ptr_cur, w_ptr_end)
    o_ptr = i_ptr_cur
    instructions, i_ptr_cur, instructions_test = gemm.compile_matrices() 
    instruction_list.append(instructions)
    instruction_list_test.append(instructions_test)
    w_ptr_cur = w_ptr_cur + node.weight_size[0]*node.weight_size[1]*sys_params.data_size

# Create FPGA
fpga_test = fpga.FPGA(sys_params, Dram_content)
# print(instruction_list_test)
fpga_test.flash(instruction_list_test)

fpga_test.execute(list(chain.from_iterable(instruction_list_test)))

print(fpga_test.extract(i_ptr_cur, (M,K)))


print(x)
