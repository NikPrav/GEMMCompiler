
import torch
import math
import isa
import layer_nodes

class GEMMCompiler:
    def __init__(self, M, N, K,sys_array, i_ptr_cur = 0, w_ptr_cur=0, w_ptr_end=0):
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
        self.dram_size = sys_array.dram_size
        self.inst_mem = sys_array.inst_mem

        # Get current pointers for input and weight
        self.i_ptr_cur = i_ptr_cur
        self.w_ptr_cur = w_ptr_cur
        # self.o_ptr_cur = o_ptr_cur

        
        # Getting the pointer correspondiing to last part of weight matrics
        self.w_ptr_end = w_ptr_end


    def compile_matrices(self):
        # Generate input matrices for the systolic array
        # self.generate_input_matrices()

        # Setting the output pointer
        self.set_io_mats()

        # Generate machine code instructions based on input matrices
        instruction_set = self.tile_systolic_array()
        machine_code = self.generate_machine_code(instruction_set)
        

        #fill in instructions
        # print(machine_code)
        # self.mem[:len(machine_code)] = machine_code.flatten()
        # hex_instructions = []
        # for instruction in machine_code:
        #     decimal_instruction = int(instruction, 2)  # Convert binary to decimal
        #     hex_instruction = format(decimal_instruction, 'x')  # Convert decimal to hexadecimal
        #     hex_instructions.append(hex_instruction)

        # # Convert hexadecimal instructions to bytes and then to a torch tensor
        # instruction_bytes = bytes.fromhex(''.join(hex_instructions))
        # self.mem[:len(instruction_bytes)] = torch.ByteTensor(list(instruction_bytes))

        

        return machine_code, self.o_buf_ptr, instruction_set

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

        mem_offset_input = self.i_ptr_cur
        mem_offset_weight = self.w_ptr_cur
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
        instruction_names = []
        
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
                        
                        # offset_tile_input = i_row*(input_dim[1])*R + i_tile*n_cols
                        # offset_tile_weight = i_col*(output_dim[1])*C + i_tile*n_cols
                        # input_tile = torch.zeros((R,n_cols))
                        # weight_tile = torch.zeros((n_cols,C))                                               

                        offset_tile_input = i_tile*(input_dim[-2])*n_cols + i_row*R
                        offset_tile_weight = i_col*C + i_tile*n_rows*output_dim[-2]

                        # Loading the inputs rowwise
                        # [TODO] Change to Columnwise
                        for i_row_tile in range(0, n_cols):
                            offset_row = i_row_tile * input_dim[-2]
                            offset_col = i_row_tile * output_dim[-2]
                            # LOAD INP_BUF offset_tile + offset_row + memory_offset
                            instruction_set.append(isa.LoadCommand(isa.BufferIDs.INPUT_BUFFER, (offset_tile_input + offset_row)*self.data_size + mem_offset_input))
                            # input_tile[i_row_tile, :] = input_array[offset_tile_input + offset_row:offset_tile_input + offset_row + n_cols]
                            # input_tile = input_tile.reshape((R, n_cols))

                            # LOAD WT_BUF offset_tile + offset_row + memory_offset
                            instruction_set.append(isa.LoadCommand(isa.BufferIDs.WEIGHT_BUFFER, (offset_tile_weight + offset_col)*self.data_size + mem_offset_weight))
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
                        offset_row = i_row_tile * input_dim[-2]
                        offset_tile = i_row * R  + i_col * C * input_dim[-2]
                        # STR OP_BUF offset_tile + offset_row + memory_offset
                        instruction_set.append(isa.StoreCommand(isa.BufferIDs.OUTPUT_BUFFER, (offset_tile + offset_row)*self.data_size + mem_offset_output))
                        # output_array[offset_tile + offset_row:offset_tile + offset_row + C] = output_tile[i_row_tile, :] 

                        # for k in range(output_tile.shape[0]):

        return instruction_set

    
    def set_io_mats(self):
        # calculate if you need to put memory after or before
        # if after then determine the addr after (one more than ouput)
        # if before then go back to the pointer

        if(self.w_ptr_end == self.i_ptr_cur):
            #set outputs
            self.o_buf_ptr = self.i_ptr_cur+self.M*self.N*self.data_size
            # self.mem[self.o_buf_ptr:self.o_buf_ptr+len(o_mat)] = o_mat

        else:
            #calc if output mem can fit inside old i mem
            if(self.i_ptr_cur - self.w_ptr_end >= self.M*self.K*self.data_size):
                self.o_buf_ptr = self.w_ptr_end
            else:
                self.o_buf_ptr = self.i_ptr_cur+self.M*self.N*self.data_size
                if(self.o_buf_ptr+self.M*self.K*self.data_size > self.dram_size):
                    #blow up
                    print("error: blew up-not enough mem to allocate the output buffer contiguously")
                # self.mem[self.o_buf_ptr:self.o_buf_ptr+self.M*self.K]

           
class SystolicArrayParams:
    def __init__(self, R, C, mem_size, i_buf_size, w_buf_size, o_buf_size, data_size=16, dram_size=(1024*1024)):


        self.R = R
        self.C = C
        self.mem_size = mem_size
        self.i_buf_size = i_buf_size
        self.w_buf_size = w_buf_size
        self.o_buf_size = o_buf_size
        self.data_size = data_size
        self.dram_size = dram_size
        self.inst_mem = 16*500


        self.inst_mem = 16*500

        self.mem = torch.zeros(dram_size)
    
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
