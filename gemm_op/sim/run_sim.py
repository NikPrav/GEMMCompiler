import torch
import torch.nn as nn
from torch.autograd import Variable

from memory_handler import DRAM
from layer_nodes import LayerNode
from compiler import GEMMCompiler, SystolicArrayParams

x = Variable(torch.randn(1,128,20))

# Initialize an empty list to store the layer info objects
node_list = []

model = nn.Sequential(nn.Linear(20, 40), nn.Linear(40, 50))

# x = torch.randn(128, 20)

output = model(x)

print(output.size())

# Loop through each layer in the model
for name,layer in model.named_children():
    if isinstance(layer, torch.nn.modules.conv.Conv2d) or isinstance(layer, torch.nn.modules.linear.Linear):
        new_node = LayerNode(name,layer, x)
        node_list.append(new_node)
        x = layer(x)

R, C = 4, 4  # Size of the systolic array
mem_size = 1096*1096  # Memory size of the FPGA
data_size = 16
i_buf_size = 16*data_size  # Input buffer size of the FPGA
w_buf_size = i_buf_size  # Weight buffer size of the FPGA
o_buf_size = R*C*data_size  # Output buffer size of the FPGA

sys_params = SystolicArrayParams(R, C, mem_size, i_buf_size, w_buf_size, o_buf_size, data_size)

# Create 1D DRAM array representation with instructions and memory
Dram_content = DRAM(mem_size)
Dram_content.InitialiseMemory(node_list, sys_params)

for node in node_list:
    M = node.input_size[-2]
    N = node.input_size[-1]
    K = node.weight_size[-2]

    cp = GEMMCompiler(M, N, K, sys_params)

print(x)
