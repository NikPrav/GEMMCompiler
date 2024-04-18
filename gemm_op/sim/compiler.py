# Normal matrix multiplecation matrices before you account for memory and buffer size

# import torch

# class GEMMCompiler:
#     def __init__(self, M, N, K, R, C, mem_size, i_buf_size, w_buf_size, o_buf_size):
#         self.M = M
#         self.N = N
#         self.K = K
#         self.R = R
#         self.C = C
#         self.mem_size = mem_size
#         self.i_buf_size = i_buf_size
#         self.w_buf_size = w_buf_size
#         self.o_buf_size = o_buf_size

#     def compile_matrices(self, matrix_A, matrix_B):
#         # Generate input matrices for the systolic array
#         input_matrices = self.generate_input_matrices(matrix_A, matrix_B)

#         # Generate machine code instructions based on input matrices
#         machine_code = self.generate_machine_code(input_matrices)

#         return input_matrices

#     def generate_input_matrices(self, matrix_A, matrix_B):
#         # Calculate the number of tiles required
#         num_tiles_M = self.M // self.R + (1 if self.M % self.R != 0 else 0)
#         num_tiles_K = self.K // self.C + (1 if self.K % self.C != 0 else 0)

#         # Pad the last generated matrix with zeros if necessary
#         padded_M = num_tiles_M * self.R
#         padded_K = num_tiles_K * self.C

#         # Pad matrices with zeros if necessary
#         padded_matrix_A = torch.nn.functional.pad(matrix_A, (0, 0, 0, padded_M - self.M))
#         padded_matrix_B = torch.nn.functional.pad(matrix_B, (0, padded_K - self.K, 0, 0))

#         # Generate input matrices
#         input_matrices_A = padded_matrix_A.split(self.R, dim=0)
#         input_matrices_B = padded_matrix_B.split(self.C, dim=1)

#         return input_matrices_A, input_matrices_B

#     def generate_machine_code(self, input_matrices):
#         # Generate machine code instructions based on input matrices
#         machine_code = []
#         for matrix_A, matrix_B in zip(*input_matrices):
#             # Generate machine code instructions for each pair of matrices
#             pass  # Implementation needed

#         return machine_code

# # Example usage
# M, N, K = 10, 12, 16  # Size of the input matrices
# R, C = 4, 8  # Size of the systolic array
# compiler = GEMMCompiler(M, N, K, R, C)
# matrix_A = torch.rand((M, N))
# matrix_B = torch.rand((N, K))
# machine_code = compiler.compile_matrices(matrix_A, matrix_B)
# print(machine_code)

# import torch

# class GEMMCompiler:
#     def __init__(self, M, N, K, R, C, mem_size, i_buf_size, w_buf_size, o_buf_size):
#         self.M = M
#         self.N = N
#         self.K = K
#         self.R = R
#         self.C = C
#         self.mem_size = mem_size
#         self.i_buf_size = i_buf_size
#         self.w_buf_size = w_buf_size
#         self.o_buf_size = o_buf_size

#     def compile_matrices(self, matrix_A, matrix_B):
#         # Generate input matrices for the systolic array
#         input_matrices = self.generate_input_matrices(matrix_A, matrix_B)

#         # Generate machine code instructions based on input matrices
#         machine_code = self.generate_machine_code(input_matrices)

#         return input_matrices

#     def generate_input_matrices(self, matrix_A, matrix_B):
#         # Calculate the number of tiles required
#         num_tiles_M = self.M // self.R + (1 if self.M % self.R != 0 else 0)
#         num_tiles_K = self.K // self.C + (1 if self.K % self.C != 0 else 0)

#         # Calculate the number of tiles for input matrices based on buffer sizes
#         num_tiles_M_i = min(num_tiles_M, self.i_buf_size // self.R)
#         num_tiles_K_i = min(num_tiles_K, self.i_buf_size // self.C)
#         num_tiles_M_w = min(num_tiles_M, self.w_buf_size // self.R)
#         num_tiles_K_w = min(num_tiles_K, self.w_buf_size // self.C)

#         # Pad the last generated matrix with zeros if necessary
#         padded_M = num_tiles_M * self.R
#         padded_K = num_tiles_K * self.C

#         # Pad matrices with zeros if necessary
#         padded_matrix_A = torch.nn.functional.pad(matrix_A, (0, 0, 0, padded_M - self.M))
#         padded_matrix_B = torch.nn.functional.pad(matrix_B, (0, padded_K - self.K, 0, 0))

#         # Generate input matrices based on buffer sizes
#         input_matrices_A = []
#         input_matrices_B = []
#         for i in range(num_tiles_M_i):
#             start_row = i * self.R
#             end_row = start_row + self.R
#             input_matrices_A.append(padded_matrix_A[start_row:end_row, :])
#         for i in range(num_tiles_K_i):
#             start_col = i * self.C
#             end_col = start_col + self.C
#             input_matrices_B.append(padded_matrix_B[:, start_col:end_col])

#         # Tile the columns of input matrix A if necessary
#         tiled_input_matrices_A = []
#         for matrix in input_matrices_A:
#             num_cols = matrix.size(1)
#             num_tiles_N = num_cols // self.i_buf_size + (1 if num_cols % self.i_buf_size != 0 else 0)
#             for j in range(num_tiles_N):
#                 start_col = j * self.i_buf_size
#                 end_col = min((j + 1) * self.i_buf_size, num_cols)
#                 tiled_input_matrices_A.append(matrix[:, start_col:end_col])

#         return tiled_input_matrices_A, input_matrices_B

#     # def generate_machine_code(self, input_matrices):
#     #     # Generate machine code instructions based on input matrices
#     #     machine_code = []
#     #     for matrix_A, matrix_B in zip(*input_matrices):
#     #         # Generate machine code instructions for loading matrices into buffers
#     #         load_cmd_A = LoadCommand(1, 0x100)  # Example load command for matrix A
#     #         load_cmd_B = LoadCommand(2, 0x200)  # Example load command for matrix B
#     #         machine_code.append(load_cmd_A.generate_bitstream())
#     #         machine_code.append(load_cmd_B.generate_bitstream())

#     #         # Generate machine code instructions for GEMM operation
#     #         gemm_cmd = GEMMCommand(1, 1, 2, 3, 0x100, 0x200, 0x300, self.M, self.N, self.K)
#     #         machine_code.append(gemm_cmd.generate_bitstream())

#     #         # Generate machine code instructions for draining systolic array
#     #         drain_cmd = DRAINSYSCommand()
#     #         machine_code.append(drain_cmd.generate_bitstream())

#     #     return machine_code

# # Example usage
# M, N, K = 10, 12, 16  # Size of the input matrices
# R, C = 4, 8  # Size of the systolic array
# mem_size = 4096  # Memory size of the FPGA
# i_buf_size = 128  # Input buffer size of the FPGA
# w_buf_size = 128  # Weight buffer size of the FPGA
# o_buf_size = 128  # Output buffer size of the FPGA
# compiler = GEMMCompiler(M, N, K, R, C, mem_size, i_buf_size, w_buf_size, o_buf_size)
# matrix_A = torch.rand((M, N))
# matrix_B = torch.rand((N, K))
# machine_code = compiler.compile_matrices(matrix_A, matrix_B)

# print(machine_code)
import torch
import math
import isa

class GEMMCompiler:
    def __init__(self, M, N, K, R, C, mem_size, i_buf_size, w_buf_size, o_buf_size, data_size):
        self.M = M
        self.N = N
        self.K = K
        self.R = R
        self.C = C
        self.mem_size = mem_size
        self.i_buf_size = i_buf_size
        self.w_buf_size = w_buf_size
        self.o_buf_size = o_buf_size
        self.data_size = 16

    def compile_matrices(self, matrix_A, matrix_B):
        # Generate input matrices for the systolic array
        input_matrices = self.generate_input_matrices(matrix_A, matrix_B)

        # Generate machine code instructions based on input matrices
        # print(input_matrices[0])
        # print(input_matrices[1])
        output_array, instruction_set = self.tile_systolic_array(input_matrices[0], input_matrices[1])
        machine_code = self.generate_machine_code(instruction_set)

        return machine_code

    def generate_input_matrices(self, matrix_A, matrix_B):
        # Calculate the number of tiles required
        num_tiles_M = self.M // self.R + (1 if self.M % self.R != 0 else 0)
        num_tiles_K = self.K // self.C + (1 if self.K % self.C != 0 else 0)

        # Pad the last generated matrix with zeros if necessary
        padded_M = num_tiles_M * self.R
        padded_K = num_tiles_K * self.C

        # Pad matrices with zeros if necessary
        padded_matrix_A = torch.nn.functional.pad(matrix_A, (0, 0, 0, padded_M - self.M))
        padded_matrix_B = torch.nn.functional.pad(matrix_B, (0, padded_K - self.K, 0, 0))

        # Generate input matrices - these are before you account for buffer size
        input_matrices_A_old = padded_matrix_A.split(self.R, dim=0)
        input_matrices_B_old = padded_matrix_B.split(self.C, dim=1)

        input_matrices_A = padded_matrix_A.flatten()
        input_matrices_B = padded_matrix_B.T.flatten()

        # # Generate input matrices based on buffer sizes
        # input_matrices_A = []
        # input_matrices_B = []

        # # Calculating tiles w.r.t. buf size
        # i_buf_tiles = math.ceil(self.R * self.N / (self.i_buf_size)) # * data_size)
        # w_buf_tiles = math.ceil(self.N * self.C / (self.w_buf_size)) # * data_size) // assume that systolic array and memory buffers are symmetric
        # i_width_per_tile = math.ceil(self.N/i_buf_tiles) # math.ceil(self.i_buf_size / self.R)
        # w_width_per_tile = math.ceil(self.N/w_buf_tiles) # math.ceil(self.w_buf_size / self.C)

        # # We assume that the size of the buffer is a multiple of R and C (4 and 4) and we made the buf size for both 128
        # # print(self.R * self.N / (self.i_buf_size))
        # # print()

        # # print(i_width_per_tile)
        # # print(self.N/i_buf_tiles)

        # for i in range(num_tiles_M):
        #     start_row = i * self.R
        #     end_row = start_row + self.R
        #     for j in range(i_buf_tiles):
        #         start_col = j * (i_width_per_tile)
        #         end_col = start_col + i_width_per_tile
        #         input_matrices_A.append(padded_matrix_A[start_row:end_row, start_col:end_col])

        # for i in range(num_tiles_K):
        #     start_col = i * self.C
        #     end_col = start_col + self.C
        #     for j in range(w_buf_tiles):
        #         start_row = j * w_width_per_tile
        #         end_row = start_row + w_width_per_tile
        #         input_matrices_B.append(padded_matrix_B[start_row:end_row, start_col:end_col])

        return input_matrices_A, input_matrices_B

    def generate_machine_code(self, instruction_set):
        # Generate machine code instructions based on input matrices
        machine_code = []

        # Take in instruction set
        # convert to bitstream
        for instruction in instruction_set:
            machine_code.append(instruction.generate_bitstream())

        # for matrix_A, matrix_B in zip(*input_matrices):

        #     # Write a for loop to put all of matrix array A into DMA memory (
        #     # 1. First pass the array into a buffer to write to memory
        #     # 2. Actually dump from the output buffer to memory 
        #     # 3. Do this for mat a and b

        #     # Generate Commands for writing from memory to buffers (load commands)
        #     # Load commands into systolic array - gonna use the tiling doc and GEMM command
        #     # Drain Systolic Array into output buffer
        #     # Generate Stores back into memory (need to keep track of addressing)

        #     # Generate machine code instructions for loading matrices into buffers
        #     load_cmd_A = isa.LoadCommand(1, 0x100)  # Example load command for matrix A
        #     load_cmd_B = isa.LoadCommand(2, 0x200)  # Example load command for matrix B
        #     machine_code.append(load_cmd_A.generate_bitstream())
        #     machine_code.append(load_cmd_B.generate_bitstream())

        #     # Generate machine code instructions for GEMM operation
        #     gemm_cmd = isa.GEMMCommand(1, 1, 2, 3, 0x100, 0x200, 0x300, self.M, self.N, self.K)
        #     machine_code.append(gemm_cmd.generate_bitstream())

        #     # Generate machine code instructions for draining systolic array
        #     drain_cmd = isa.DRAINSYSCommand()
        #     machine_code.append(drain_cmd.generate_bitstream())

        return machine_code
    
    def tile_systolic_array(self, input_array, weight_array):
        # Tiling the input and weight arrays, and returning a 1D output array
        # Returns the instruction set, and the expected output of the GEMM (for now)
        # input_array: 1D numpy array padded to mach R dimensions
        # weight_array: 1D numpy array padded to match C dimensions (stored as transposed)

        input_dim = [self.M, self.N]
        output_dim = [self.K, self.N]

        mem_offset_input = 0
        mem_offset_weight = 0
        mem_offset_output = 0

        buf_size = self.i_buf_size
        data_size = self.data_size

        R = self.R
        C = self.C

        # Check if the dimensions are correct
        assert input_dim[1] == output_dim[1], "Mismatched dimensions"

        # Initialize output array
        # storing values for sanity check
        output_array = torch.zeros(input_dim[0] * output_dim[0])

        # Initializing the instruction array
        instruction_set = []
        
        # Calculating number of columns per tile
        n_cols = int(buf_size / (R * data_size))
        n_rows = int(buf_size / (C * data_size))

        # Calculating the number of tiles per row
        n_tiles_per_row = int(input_dim[1] / n_cols)
        n_tiles_per_column = int(output_dim[1] / n_rows)

        # Tile the multiplication rowise for inputs
        for i_row in range(0, input_dim[0]//R):

                # Tile the multiplication columnwise for weights
                for i_col in range(0, output_dim[0]//C):
                    # Tiling for buffer size
                    # Initializing an empty systolic array
                    output_tile = torch.zeros((R, C))
                    for i_tile in range(0, n_tiles_per_row):
                        # Get the current tile
                        # Load to buffer from mem
                        # LOAD INP_BUF i*R*input_dim[1]
                        
                        # Calculating the offset by consider the tiles before the current tile
                        # tiles in current row + tiles in previous rows
                        # loading rowise 
                        
                        offset_tile_input = i_row*(input_dim[1])*R + i_tile*n_cols
                        offset_tile_weight = i_col*(output_dim[1])*C + i_tile*n_cols
                        input_tile = torch.zeros((R,n_cols))
                        weight_tile = torch.zeros((n_cols,C))                                               

                        # Loading the inputs rowwise
                         
                        for i_row_tile in range(0, R):
                            offset_row = i_row_tile * n_cols * n_tiles_per_row
                            # LOAD INP_BUF offset_tile + offset_row + memory_offset
                            instruction_set.append(isa.LoadCommand(isa.BufferIDs.INPUT_BUFFER, offset_tile_input + offset_row + mem_offset_input))
                            input_tile[i_row_tile, :] = input_array[offset_tile_input + offset_row:offset_tile_input + offset_row + n_cols]
                            # input_tile = input_tile.reshape((R, n_cols))

                            # LOAD WT_BUF offset_tile + offset_row + memory_offset
                            instruction_set.append(isa.LoadCommand(isa.BufferIDs.WEIGHT_BUFFER, offset_tile_weight + offset_row + mem_offset_weight))
                            weight_tile[:, i_row_tile] = weight_array[offset_tile_weight + offset_row:offset_tile_weight + offset_row + n_cols].T
                            # weight_tile = weight_tile.reshape((n_cols, C)).T
                        
                        # Perform the multiplication
                        # GEMM
                        instruction_set.append(isa.GEMMCommand(n_cols))
                        output_tile += torch.matmul(input_tile, weight_tile) 

                    # Drain the array 
                    # DRAIN         
                    instruction_set.append(isa.DRAINSYSCommand())

                    # Store the result in the output array
                    
                    for i_row_tile in range(0, R):
                        offset_row = i_row_tile * C * output_dim[0]//C
                        offset_tile = i_row * C * R * output_dim[0]//C  + i_col * C
                        # STR OP_BUF offset_tile + offset_row + memory_offset
                        instruction_set.append(isa.StoreCommand(isa.BufferIDs.OUTPUT_BUFFER, offset_tile + offset_row + mem_offset_output))
                        output_array[offset_tile + offset_row:offset_tile + offset_row + C] = output_tile[i_row_tile, :] 

                        # for k in range(output_tile.shape[0]):
                        

                

        return output_array, instruction_set

# Example usage
M, N, K = 10, 12, 16  # Size of the input matrices
R, C = 4, 4  # Size of the systolic array
mem_size = 4096  # Memory size of the FPGA
data_size = 16
i_buf_size = 16*data_size  # Input buffer size of the FPGA
w_buf_size = i_buf_size  # Weight buffer size of the FPGA
o_buf_size = R*C*data_size  # Output buffer size of the FPGA
compiler = GEMMCompiler(M, N, K, R, C, mem_size, i_buf_size, w_buf_size, o_buf_size, 16)
matrix_A = torch.rand((M, N))
matrix_B = torch.rand((N, K))
machine_code = compiler.compile_matrices(matrix_A, matrix_B)

print("hey")
# print(len(machine_code[0][0]))
# print(len(machine_code[0][0][0]))
# print(len(machine_code[0][0][0][0]))
# print(machine_code[1])
# print(machine_code[1][0]))
