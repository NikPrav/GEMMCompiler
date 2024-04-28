import torch
import torch.nn.functional as F
from torch import nn
import numpy as np
import matplotlib.pyplot as plt
from itertools import chain

from PIL import Image


from memory_handler import DRAM
from layer_nodes import LayerNode
from compiler import GEMMCompiler, SystolicArrayParams
from padding import padding_func, padding_func_ip
import fpga


def im2col(input, kernel):
    # Unfold the image and filter
    img_unfolded = F.unfold(input.float(), kernel_size=kernel.shape[2:]).transpose(1, 2)
    kernel = kernel.view(kernel.size(0), -1).t()
    return img_unfolded, kernel


def read_image(path):
    img = Image.open(path)

    if img.mode != 'L':
        img = img.convert('L')

    img = np.array(img)
    img = torch.tensor(img, dtype=torch.int8)

    return img


if __name__ == '__main__':

    # Setting Systolic Array Parameters
    R, C = 2, 2  # Size of the systolic array
    mem_size = 1096*1096  # Memory size of the FPGA
    data_size = 16
    i_buf_size = 16*data_size  # Input buffer size of the FPGA
    w_buf_size = i_buf_size  # Weight buffer size of the FPGA
    o_buf_size = R*C*data_size  # Output buffer size of the FPGA

    sys_params = SystolicArrayParams(R, C, mem_size, i_buf_size, w_buf_size, o_buf_size, data_size)


    # Read the image
    img = read_image('gemm_op/100.png')


    # Convert the image to a tensor
    img = torch.tensor(img, dtype=torch.int16)


    # Creating an edge detection filter
    edge_filter = torch.tensor([[-1, -1, -1], [-1, 8, -1], [-1, -1, -1]], dtype=torch.float16)

    # Reshaping the filter and image to the correct format
    edge_filter = edge_filter.reshape(1, 1, edge_filter.shape[1], edge_filter.shape[0])
    img = img.reshape(1, 1, img.shape[0], img.shape[1])


    # Applying the filter to the image
    edge_detected = torch.nn.functional.conv2d(img.float(), edge_filter.float())


    # Converting the image and filter to im2col format
    img_unfolded, edge_filter = im2col(img, edge_filter)

    print(img_unfolded.shape)
    print(edge_filter.shape)


    out_unf = img_unfolded.float().matmul(edge_filter.float())
    out_unf = out_unf.reshape(1,1,26,26)
    # Display the edge detected image
    # plt.imshow(out_unf.squeeze(0).squeeze(0).detach().numpy(), cmap='gray')
    # plt.show()



    # Initialize an empty list to store the layer info objects
    node_list = []

    # Create the model
    model = nn.Sequential(nn.Linear(edge_filter.shape[0],edge_filter.shape[1]).float())

    output = model(img_unfolded.float())
    x = img_unfolded.float()
    # print(output.size())

    

    model[0].weight = nn.Parameter(data=edge_filter.squeeze(0).squeeze(0).float().t())
    # model[0].weight = nn.Parameter(data=torch.tensor([[1,2,3,4],[5,6,7,8],[9,10,11,12], [13,14,15,16]], dtype=torch.float16))


    # Loop through each layer in the model and padding
    for name, layer in model.named_children():
        if isinstance(layer, torch.nn.modules.conv.Conv2d) or isinstance(layer, torch.nn.modules.linear.Linear):
            new_node = LayerNode(name,layer, x)
            padded_node = padding_func(new_node,sys_params)
            node_list.append(padded_node)
            x = layer(x)

    # if isinstance(layer, torch.nn.modules.conv.Conv2d) or isinstance(layer, torch.nn.modules.linear.Linear):
    #     new_node = LayerNode("gemm",layer, x)
    #     padded_node = padding_func(new_node,sys_params)
    #     node_list.append(padded_node)
    #     x = layer(x)


    # Create 1D DRAM array representation with instructions and memory
    Dram_content = DRAM(mem_size, sys_params)
    w_ptr_end = Dram_content.mem_init(node_list, sys_params)

    input = padding_func_ip(img_unfolded.squeeze(0).squeeze(0), sys_params)

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


    # Writing to text file
    Dram_content.generate_lists(instruction_list)

    # Create FPGA
    fpga_test = fpga.FPGA(sys_params, Dram_content)
    # print(instruction_list_test)
    fpga_test.flash(instruction_list_test)

    fpga_test.execute(list(chain.from_iterable(instruction_list_test)))

    # plotting all the images
    fig, axs = plt.subplots(1,3, figsize=(15,5))
    axs[0].imshow(img.squeeze(0).squeeze(0).detach().numpy(), cmap='gray')
    axs[1].imshow(edge_detected.squeeze(0).squeeze(0).detach().numpy(), cmap='gray')
    axs[2].imshow(fpga_test.extract(i_ptr_cur-sys_params.inst_mem, (26,26)).T, cmap='gray')
    axs[0].set_title('Original Image')
    axs[1].set_title('Edge Detected Image')
    axs[2].set_title('Edge Detected Image from the FPGA')
    plt.show()
    

    print(x)