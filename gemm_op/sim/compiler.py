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
    def __init__(self, M, N, K, R, C, mem_size, i_buf_size, w_buf_size, o_buf_size, data_type):
        self.M = M
        self.N = N
        self.K = K
        self.R = R
        self.C = C
        self.mem_size = mem_size
        self.i_buf_size = i_buf_size
        self.w_buf_size = w_buf_size
        self.o_buf_size = o_buf_size
        self.data_type = 16

    def compile_matrices(self, matrix_A, matrix_B):
        # Generate input matrices for the systolic array
        input_matrices = self.generate_input_matrices(matrix_A, matrix_B)

        # Generate machine code instructions based on input matrices
        # print(input_matrices[0])
        # print(input_matrices[1])
        machine_code = self.generate_machine_code([input_matrices[0], input_matrices[1]])

        return input_matrices, machine_code

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

        # Generate input matrices based on buffer sizes
        input_matrices_A = []
        input_matrices_B = []

        # Calculating tiles w.r.t. buf size
        i_buf_tiles = math.ceil(self.R * self.N / (self.i_buf_size)) # * data_type)
        w_buf_tiles = math.ceil(self.N * self.C / (self.w_buf_size)) # * data_type) // assume that systolic array and memory buffers are symmetric
        i_width_per_tile = math.ceil(self.N/i_buf_tiles) # math.ceil(self.i_buf_size / self.R)
        w_width_per_tile = math.ceil(self.N/w_buf_tiles) # math.ceil(self.w_buf_size / self.C)

        # We assume that the size of the buffer is a multiple of R and C (4 and 4) and we made the buf size for both 128
        # print(self.R * self.N / (self.i_buf_size))
        # print()

        # print(i_width_per_tile)
        # print(self.N/i_buf_tiles)

        for i in range(num_tiles_M):
            start_row = i * self.R
            end_row = start_row + self.R
            for j in range(i_buf_tiles):
                start_col = j * (i_width_per_tile)
                end_col = start_col + i_width_per_tile
                input_matrices_A.append(padded_matrix_A[start_row:end_row, start_col:end_col])

        for i in range(num_tiles_K):
            start_col = i * self.C
            end_col = start_col + self.C
            for j in range(w_buf_tiles):
                start_row = j * w_width_per_tile
                end_row = start_row + w_width_per_tile
                input_matrices_B.append(padded_matrix_B[start_row:end_row, start_col:end_col])

        return input_matrices_A, input_matrices_B , input_matrices_A_old, input_matrices_B_old

    def generate_machine_code(self, input_matrices):
        # Generate machine code instructions based on input matrices
        machine_code = []
        for matrix_A, matrix_B in zip(*input_matrices):

            # Write a for loop to put all of matrix array A into DMA memory (
            # 1. First pass the array into a buffer to write to memory
            # 2. Actually dump from the output buffer to memory 
            # 3. Do this for mat a and b

            # Generate Commands for writing from memory to buffers (load commands)
            # Load commands into systolic array - gonna use the tiling doc and GEMM command
            # Drain Systolic Array into output buffer
            # Generate Stores back into memory (need to keep track of addressing)

            # Generate machine code instructions for loading matrices into buffers
            load_cmd_A = isa.LoadCommand(1, 0x100)  # Example load command for matrix A
            load_cmd_B = isa.LoadCommand(2, 0x200)  # Example load command for matrix B
            machine_code.append(load_cmd_A.generate_bitstream())
            machine_code.append(load_cmd_B.generate_bitstream())

            # Generate machine code instructions for GEMM operation
            gemm_cmd = isa.GEMMCommand(1, 1, 2, 3, 0x100, 0x200, 0x300, self.M, self.N, self.K)
            machine_code.append(gemm_cmd.generate_bitstream())

            # Generate machine code instructions for draining systolic array
            drain_cmd = isa.DRAINSYSCommand()
            machine_code.append(drain_cmd.generate_bitstream())

        return machine_code

# Example usage
M, N, K = 10, 12, 16  # Size of the input matrices
R, C = 4, 8  # Size of the systolic array
mem_size = 4096  # Memory size of the FPGA
i_buf_size = 24  # Input buffer size of the FPGA
w_buf_size = 128  # Weight buffer size of the FPGA
o_buf_size = 128  # Output buffer size of the FPGA
compiler = GEMMCompiler(M, N, K, R, C, mem_size, i_buf_size, w_buf_size, o_buf_size, 16)
matrix_A = torch.rand((M, N))
matrix_B = torch.rand((N, K))
machine_code = compiler.compile_matrices(matrix_A, matrix_B)
print(len(machine_code[0][0]))
print(len(machine_code[0][0][0]))
print(len(machine_code[0][0][0][0]))
print(machine_code[1])
# print(machine_code[1][0]))
