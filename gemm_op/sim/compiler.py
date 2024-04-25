
import torch
import math
import isa
import layer_nodes

class GEMMCompiler:
    def __init__(self, M, N, K,sys_array, start_adr=0, i_buf_ptr = 0, w_buf_ptr=0, o_buf_ptr=0 ):
        self.M = M
        self.N = N
        self.K = K

        self.R = sys_array.R
        self.C = sys_array.C
        self.mem_size = sys_array.mem_size
        self.i_buf_size = sys_array.i_buf_size
        self.w_buf_size = sys_array.w_buf_size
        self.o_buf_size = sys_array.o_buf_size
        self.data_size = sys_array.data_size
        self.sram_size = sys_array.sram_size
        self.inst_mem = sys_array.inst_mem

        self.i_buf_ptr = i_buf_ptr
        self.w_buf_ptr = w_buf_ptr
        self.o_buf_ptr = o_buf_ptr
        # self.wt_end_ptr = 

        # self.inst_mem = 16*500

        # Example memory code
        self.start_adr = start_adr
        self.mem = torch.zeros(self.sram_size)


    def compile_matrices(self, matrix_A, matrix_B):
        # Generate input matrices for the systolic array
        self.generate_input_matrices()

        # Generate machine code instructions based on input matrices
        # print(input_matrices[0])
        # print(input_matrices[1])
        # self.mem_management(input_matrices[0], input_matrices[1], self.inst_mem)
        self.mem_management(self.inst_mem)

        output_array, instruction_set = self.tile_systolic_array()
        # self.mmap_init()
        machine_code = self.generate_machine_code(instruction_set)
        # print(len(machine_code)*16)
        # pass in machine code offset

        #fill in instructions
        # print(machine_code)
        # self.mem[:len(machine_code)] = machine_code.flatten()
        hex_instructions = []
        for instruction in machine_code:
            decimal_instruction = int(instruction, 2)  # Convert binary to decimal
            hex_instruction = format(decimal_instruction, 'x')  # Convert decimal to hexadecimal
            hex_instructions.append(hex_instruction)

        # Convert hexadecimal instructions to bytes and then to a torch tensor
        instruction_bytes = bytes.fromhex(''.join(hex_instructions))
        # self.mem[:len(instruction_bytes)] = torch.ByteTensor(list(instruction_bytes))

        

        return machine_code

    def generate_input_matrices(self):
        # Pad the input matrices to match the systolic array dimensions
        # Flatten the matrices to 1D arrays

        # Calculate the number of tiles required
        num_tiles_M = self.M // self.R + (1 if self.M % self.R != 0 else 0)
        num_tiles_K = self.K // self.C + (1 if self.K % self.C != 0 else 0)

        num_tiles_N = self.N // (self.i_buf_size/(self.R*data_size)) + (1 if self.N % (self.i_buf_size/(self.R*data_size)) != 0 else 0)

        # Pad the last generated matrix with zeros if necessary
        self.M = num_tiles_M * self.R
        self.N = num_tiles_N * (self.i_buf_size/(self.R*data_size))
        self.K = num_tiles_K * self.C

        # Pad matrices with zeros if necessary
        # padded_matrix_A = torch.nn.functional.pad(matrix_A, (0, 0, 0, padded_M - self.M))
        # padded_matrix_B = torch.nn.functional.pad(matrix_B, (0, padded_K - self.K, 0, 0))

        # Generate input matrices - these are before you account for buffer size
        # input_matrices_A_old = padded_matrix_A.split(self.R, dim=0)
        # input_matrices_B_old = padded_matrix_B.split(self.C, dim=1)

        # input_matrices_A = padded_matrix_A.flatten()
        # input_matrices_B = padded_matrix_B.T.flatten()

        

        return 

    def generate_machine_code(self, instruction_set):
        # Generate machine code instructions based on input matrices
        machine_code = []

        # Take in instruction set
        # convert to bitstream
        for instruction in instruction_set:
            machine_code.append(instruction.generate_bitstream())

        

        return machine_code
    
    def tile_systolic_array(self):
        # Tiling the input and weight arrays, and returning a 1D output array
        # Returns the instruction set, and the expected output of the GEMM (for now)
        # input_array: 1D numpy array padded to mach R dimensions
        # weight_array: 1D numpy array padded to match C dimensions (stored as transposed)

        input_dim = [self.M, self.N]
        output_dim = [self.K, self.N]

        mem_offset_input = self.i_buf_ptr
        mem_offset_weight = self.w_buf_ptr
        mem_offset_output = self.o_buf_ptr

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
                        # [TODO] Change to Columnwise
                        for i_row_tile in range(0, R):
                            offset_row = i_row_tile * n_cols * n_tiles_per_row
                            # LOAD INP_BUF offset_tile + offset_row + memory_offset
                            instruction_set.append(isa.LoadCommand(isa.BufferIDs.INPUT_BUFFER, offset_tile_input + offset_row + mem_offset_input))
                            # input_tile[i_row_tile, :] = input_array[offset_tile_input + offset_row:offset_tile_input + offset_row + n_cols]
                            # input_tile = input_tile.reshape((R, n_cols))

                            # LOAD WT_BUF offset_tile + offset_row + memory_offset
                            instruction_set.append(isa.LoadCommand(isa.BufferIDs.WEIGHT_BUFFER, offset_tile_weight + offset_row + mem_offset_weight))
                            # weight_tile[:, i_row_tile] = weight_array[offset_tile_weight + offset_row:offset_tile_weight + offset_row + n_cols].T
                            # weight_tile = weight_tile.reshape((n_cols, C)).T
                        
                        # Perform the multiplication
                        # GEMM
                        instruction_set.append(isa.GEMMCommand(n_cols))
                        # output_tile += torch.matmul(input_tile, weight_tile) 

                    # Drain the array 
                    # DRAIN         
                    instruction_set.append(isa.DRAINSYSCommand())

                    # Store the result in the output array
                    
                    for i_row_tile in range(0, R):
                        offset_row = i_row_tile * C * output_dim[0]//C
                        offset_tile = i_row * C * R * output_dim[0]//C  + i_col * C
                        # STR OP_BUF offset_tile + offset_row + memory_offset
                        instruction_set.append(isa.StoreCommand(isa.BufferIDs.OUTPUT_BUFFER, offset_tile + offset_row + mem_offset_output))
                        # output_array[offset_tile + offset_row:offset_tile + offset_row + C] = output_tile[i_row_tile, :] 

                        # for k in range(output_tile.shape[0]):
                        

                

        return output_array, instruction_set

    #Function to call for when you need to store memory 
    def mem_management(self,m_code_len):
        # determine the size of the memory
        # place instructions into memory
        self.start_adr = m_code_len

        # store weight buffers in the matrix(do this at first index)
        self.w_buf_ptr = self.start_adr
        # print(i_mat.size())
        # print(i_mat.flatten())
        # print(w_mat.flatten().size())
        # print(w_mat.size())
        print(self.mem.size())
        # self.mem.extend([i_mat])
        # self.mem[m_code_len+1:m_code_len+1+self.N*self.K] = w_mat # could do len(w_mat) instead of buf_size

        # for first time calling function, set pointers for o and i
        self.set_io_mats(self.N*self.K+2,self.N*self.K+2)
        # self.mem[:len(w_mat.flatten())] = w_mat.flatten()
    
    def set_io_mats(self, start_ptr, i_ptr):
        # calculate if you need to put memory after or before
        # if after then determine the addr after (one more than ouput)
        # if before then go back to the pointer

        if(start_ptr == i_ptr):
            #set inputs
            # self.mem[start_ptr:start_ptr+self.M*self.N] = i_mat
            self.i_buf_ptr = start_ptr

            #set outputs
            self.o_buf_ptr = start_ptr+self.M*self.N
            # self.mem[self.o_buf_ptr:self.o_buf_ptr+len(o_mat)] = o_mat

        else:
            #calc if output mem can fit inside old i mem
            if(i_ptr-start_ptr >= self.M*self.K*self.data_size):
                self.o_buf_ptr = start_ptr
            else:
                self.o_buf_ptr = i_ptr+self.M*self.K*self.data_size
                if(self.o_buf_ptr+self.M*self.K*self.data_size):
                    #blow up
                    print("error: blew up-not enough mem to allocate the output buffer contiguously")
                # self.mem[self.o_buf_ptr:self.o_buf_ptr+self.M*self.K]

            
            


            return i_ptr+self.M*self.K
        

class SystolicArrayParams:
    def __init__(self, R, C, mem_size, i_buf_size, w_buf_size, o_buf_size, data_size=16, sram_size=(1024*1024)):


        self.R = R
        self.C = C
        self.mem_size = mem_size
        self.i_buf_size = i_buf_size
        self.w_buf_size = w_buf_size
        self.o_buf_size = o_buf_size
        self.data_size = data_size
        self.sram_size = sram_size
        self.inst_mem = 16*500


        self.inst_mem = 16*500

        self.mem = torch.zeros(sram_size)
    
# Example usage
if __name__ in '__main__':
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
