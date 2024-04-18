
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


