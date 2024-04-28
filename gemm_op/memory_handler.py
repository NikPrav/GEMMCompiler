import torch
import numpy as np
import compiler

DATA_SIZE = 16

class DRAM:
    def __init__(self, size, sys_params: compiler.SystolicArrayParams):
        self.size = size
        self.data = np.zeros(size - sys_params.inst_mem)
        self.instructions = np.zeros(sys_params.inst_mem)
        self.weights_size = 0
        self.sys_params = sys_params

    def flash_inputs(self, input_array, in_ptr):
        # Takes in 1D array, appends it to memory at in_ptr
        in_ptr = (in_ptr-self.sys_params.inst_mem)//self.sys_params.data_size
        self.data[in_ptr:in_ptr+input_array.shape[0]] = input_array
    
    def generate_weight_matrix(self, matrix_B, sys_params):
        # Pad the input matrices to match the systolic array dimensions
        # Flatten the matrices to 1D arrays

        # Calculate the number of tiles required
        # num_tiles_M = self.M // self.R + (1 if self.M % self.R != 0 else 0)
        num_tiles_K = matrix_B.shape[-1] // sys_params.C + (1 if matrix_B.shape[-2] % sys_params.C != 0 else 0)

        # Pad the last generated matrix with zeros if necessary
        # padded_M = num_tiles_M * self.R
        padded_K = num_tiles_K * sys_params.C

        # Pad matrices with zeros if necessary
        # padded_matrix_A = torch.nn.functional.pad(matrix_A, (0, 0, 0, padded_M - self.M))
        padded_matrix_B = torch.nn.functional.pad(matrix_B, (0, padded_K - matrix_B.shape, 0, 0))

        # Generate input matrices - these are before you account for buffer size
        # input_matrices_A_old = padded_matrix_A.split(self.R, dim=0)
        input_matrices_B_old = padded_matrix_B.split(self.C, dim=1)

        # input_matrices_A = padded_matrix_A.flatten()
        input_matrices_B = padded_matrix_B.T.flatten()

        

        return input_matrices_B

    def mem_init(self, node_list, sys_params):
        weights = []

        # goes through each layer in the model
        # pads and generates the weight matrices
        for node in node_list:
            M = node.input_size[-2]
            N = node.input_size[-1]
            K = node.weight_size[-2]
            weights.append(node.weights.T.flatten().detach().numpy())

            # cp = GEMMCompiler(M, N, K, sys_params)

        weights = np.concatenate(weights)
        # leaves room for the instruction set
        self.data[0:0+weights.shape[0]] = weights
        self.weights_size = weights.shape[0]*sys_params.data_size

        wt_ptr_end = sys_params.inst_mem + self.weights_size

        return wt_ptr_end

    def write(self, addr, data):
        self.data[addr] = data
    
    def write_to_text(self, filename):
        with open(filename, "w") as f:
            for i in range(self.size):
                f.write(str(self.data[i]) + "\n")

    def read(self, addr):
        return self.data[addr]
    
    def generate_lists(self,instruction_list):
        # writing the instructions into the DRAM
        with open("instruction_list.txt", "w") as file:
            # Iterate through each element in the list
            for row in instruction_list:
                for element in row:
                    # Write the element to the file
                    file.write(str(element) + "\n")  # Add a newline character to separate elements

        # Change this for actual FPGA
        cur_entry_mem = 0
        with open("data_list.txt", "w") as file:
            # Iterate through each element in the list
            for weight_entry in self.data:
                file.write(str(format(int(weight_entry),f'0{16}b')) + "\n")  # Add a newline character to separate elements
                cur_entry_mem += 1

    def __str__(self):
        return str(self.data)