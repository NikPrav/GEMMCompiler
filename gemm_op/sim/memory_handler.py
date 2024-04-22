import torch

class DRAM:
    def __init__(self, size):
        self.size = size
        self.data = torch.zeros(size)
        self.weights_size = 0
    
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
        padded_matrix_B = torch.nn.functional.pad(matrix_B, (0, padded_K - self.K, 0, 0))

        # Generate input matrices - these are before you account for buffer size
        # input_matrices_A_old = padded_matrix_A.split(self.R, dim=0)
        input_matrices_B_old = padded_matrix_B.split(self.C, dim=1)

        # input_matrices_A = padded_matrix_A.flatten()
        input_matrices_B = padded_matrix_B.T.flatten()

        

        return input_matrices_B

    def InitialiseMemory(self, node_list, sys_params):
        weights = []

        # goes through each layer in the model
        # pads and generates the weight matrices
        for node in node_list:
            M = node.input_size[-2]
            N = node.input_size[-1]
            K = node.weight_size[-2]
            weights.append(self.generate_weight_matrix(node.weights, sys_params))

            # cp = GEMMCompiler(M, N, K, sys_params)
        
        torch.cat(weights, dim=0)
        # leaves room for the instruction set
        self.data[:sys_params.inst_mem] = weights
        self.weights_size = sys_params.inst_mem + weights.size()

    def write(self, addr, data):
        self.data[addr] = data

    def read(self, addr):
        return self.data[addr]

    def __str__(self):
        return str(self.data)