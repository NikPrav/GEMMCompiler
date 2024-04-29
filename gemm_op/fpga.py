
# Write a class that makes FPGA
# Has fifo i_mem, o_mem, fifo w_mem, dram fields all sized 1k and dram sized at 4k
# Has systolic array - size at defition of FPGA
# Had methods for:
# - writing in instructions into instruction buffer
# - dealing with mem_addr (from instruction to chip)
# - sending information through dma to fpga
# - method to handle each instruction (LoadCommand, StoreCommand, GEMMCommand, DRAINSYSCommand)

# For GEMM command, make helper commands to write the information from memory to buffer. After populating the buffers, pass the information into the systolic array (output stationary), then make a helper function to determine if the output has completed the matrix multiplication
# Remember that the input data is going to be tiled and should notify the users when the tiling is complete

import torch
import memory_handler
import compiler
import numpy as np
from torch import nn
from torch.autograd import Variable

class FPGA:
    def __init__(self, sys_params, dram, offset_row, offset_col):
        # self.n_ = 
        self.sys_params = sys_params
        self.i_buf = np.zeros((sys_params.R, sys_params.i_buf_size//(sys_params.R*sys_params.data_size)))
        self.o_buf = np.zeros((sys_params.R, sys_params.C))
        self.w_buf = np.zeros((sys_params.w_buf_size//(sys_params.C*sys_params.data_size), sys_params.C))
        self.dram = dram
        self.instr_list = []
        self.sys_array = np.zeros((self.sys_params.R,self.sys_params.C))
        self.offset_row = offset_row
        self.offset_col = offset_col

    def flash(self, instructions):
        print(len(instructions))
        # self.dram.data[0:(instructions.size)*16] = dram
        self.instr_list = instructions
    
    def extract(self, i_ptr, shape):
        return self.dram.data[i_ptr//self.sys_params.data_size:i_ptr//self.sys_params.data_size+shape[0]*shape[1]].reshape(shape).T

    def execute(self, instruction_list):
        i_buf_col = 0
        w_buf_row = 0
        o_buf_col = 0
        for pc, instr in zip(range(len(instruction_list)), instruction_list):
            if (instr.name == "LD"):
                instr.mem_addr = (instr.mem_addr-self.sys_params.inst_mem) // self.sys_params.data_size

                for i in range(self.sys_params.i_buf_size//(self.sys_params.R*self.sys_params.data_size)):
                    # self.i_buf[i, i_buf_col] = self.dram.data[instr.mem_addr + i]
                    

                    if (instr.buf_id == 1):
                        offset = i*(self.offset_row//self.sys_params.data_size) 
                        self.i_buf[:, i] = self.dram.data[instr.mem_addr + offset:instr.mem_addr + offset + self.sys_params.R].T
                        # for i in range(self.sys_params.i_buf_size/self.R):
                        # self.i_buf[:, i] = self.dram[instr.mem_addr + i*self.sys_params.R:instr.mem_addr + self.sys_params.R + self.sys_params*i ].T

                        i_buf_col += 1
                    if (instr.buf_id == 2):
                        offset = i*(self.offset_col//self.sys_params.data_size) 
                        # for i in range(self.sys_params.w_buf_size/self.C):
                        # self.w_buf[i, :] = self.dram[instr.mem_addr + self.sys_params.C*i:instr.mem_addr + self.sys_params.C + self.sys_params.C*i ]

                        self.w_buf[i, :] = self.dram.data[instr.mem_addr + offset:instr.mem_addr + offset + self.sys_params.C ]
                        w_buf_row += 1
                    if (instr.buf_id == 3):
                        # for i in range(self.sys_params.i_buf_size/self.R):
                        # self.o_buf[:, i] = self.dram[instr.mem_addr + i*self.sys_params.R:instr.mem_addr + self.sys_params.R + self.sys_params*i ].T
                        self.o_buf[:, i] = self.dram.data[instr.mem_addr + offset:instr.mem_addr + offset + self.sys_params.R ].T
                        o_buf_col += 1


                    # self.i_buf[:, i_buf_col] = self.dram[instr.mem_addr:instr.mem_addr + self.sys_params.R ]
       
            elif (instr.name == "STR"):
                instr.mem_addr = (instr.mem_addr-self.sys_params.inst_mem) // self.sys_params.data_size
                for i in range(self.sys_params.R):
                    if (instr.buf_id == 3):
                        offset = (self.offset_row//self.sys_params.data_size) * i
                        # for i in range(self.sys_params.o_buf_size/self.sys_params.R):
                        self.dram.data[instr.mem_addr + offset:instr.mem_addr + offset + self.sys_params.R] = self.o_buf[:, i]
                        # o_buf_col += 1

            elif (instr.name == "GEMM"):
                self.sys_array += self.i_buf @ self.w_buf
                i_buf_col = 0
                w_buf_row = 0
                o_buf_col = 0
                # for i in range():


                # for n in range():
                # sys_array = self.i_buf @ self.w_buf

            elif (instr.name == "DRAINSYS"):
                # for i in range(self.R):
                # for i in range(self.C):
                self.o_buf = self.sys_array
                self.sys_array = np.zeros((self.sys_params.R,self.sys_params.C))


