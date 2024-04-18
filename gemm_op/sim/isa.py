from enum import IntEnum
import torch

# buffer ids
class BufferIDs(IntEnum):
    INPUT_BUFFER = 1
    WEIGHT_BUFFER = 2
    OUTPUT_BUFFER = 3


class LoadCommand:
    def __init__(self, buf_id, mem_addr):
        self.buf_id = buf_id
        self.mem_addr = mem_addr

    def execute_command(self):
        # Simulating loading data from memory
        data = self.load_data_from_memory(self.mem_addr)
        return data

    def generate_bitstream(self):
        # Generate bitstream for the load command
        function_type = '0010'  # 4 bits for function type (load command)
        buf_id_bits = format(self.buf_id, '02b')  # 2 bits for buf_id
        mem_addr_bits = format(self.mem_addr, '010b')  # 10 bits for mem_addr
        bitstream = function_type + buf_id_bits + mem_addr_bits
        return bitstream

    def load_data_from_memory(self, mem_addr):
        # Simulated function to load data from memory
        memory = {0x100: 'Data1', 0x200: 'Data2', 0x300: 'Data3'}
        if mem_addr in memory:
            return memory[mem_addr]
        else:
            return None

# Example usage
# load_cmd = LoadCommand(1, 0x100)
# data = load_cmd.execute_command()
# print(f"Loaded data '{data}' from memory address {load_cmd.mem_addr} to buffer {load_cmd.buf_id}")
# print("Generated bitstream:", load_cmd.generate_bitstream())
        
class StoreCommand:
    def __init__(self, buf_id, mem_addr):
        self.buf_id = buf_id
        self.mem_addr = mem_addr
        # self.data = data

    # def execute_command(self):
    #     # Simulating storing data to memory
    #     self.store_data_to_memory(self.mem_addr, self.data)

    def generate_bitstream(self):
        # Generate bitstream for the store command
        function_type = '0011'  # 4 bits for function type (store command)
        buf_id_bits = format(self.buf_id, '02b')  # 2 bits for buf_id
        mem_addr_bits = format(self.mem_addr, '010b')  # 10 bits for mem_addr
        bitstream = function_type + buf_id_bits + mem_addr_bits
        return bitstream

    def store_data_to_memory(self, mem_addr, data):
        # Simulated function to store data to memory
        memory = {}
        memory[mem_addr] = data
        print(f"Stored data '{data}' to memory address {mem_addr}.")



class GEMMCommand:
    # def __init__(self, n, buf_id_A, buf_id_B, buf_id_C, mem_addr_A, mem_addr_B, mem_addr_C, M, N, K):
    #     self.n = n
    #     self.buf_id_A = buf_id_A
    #     self.buf_id_B = buf_id_B
    #     self.buf_id_C = buf_id_C
    #     self.mem_addr_A = mem_addr_A
    #     self.mem_addr_B = mem_addr_B
    #     self.mem_addr_C = mem_addr_C
    #     self.M = M
    #     self.N = N
    #     self.K = K
    def __init__(self, n):
        self.n = n

    def execute_command(self):
        # Simulating GEMM operation
        for i in range(self.n):
            self.perform_gemm()

    def perform_gemm(self):
        # Simulated function to perform GEMM operation
        print(f"Performing GEMM operation with buf_id_A={self.buf_id_A}, buf_id_B={self.buf_id_B}, buf_id_C={self.buf_id_C}, "
              f"mem_addr_A={self.mem_addr_A}, mem_addr_B={self.mem_addr_B}, mem_addr_C={self.mem_addr_C}, "
              f"M={self.M}, N={self.N}, K={self.K}")

    # def generate_bitstream(self):
    #     # Generate bitstream for the GEMM operation
    #     function_type = '0100'  # 4 bits for function type (GEMM operation)
    #     buf_id_A_bits = format(self.buf_id_A, '02b')  # 2 bits for buf_id_A
    #     buf_id_B_bits = format(self.buf_id_B, '02b')  # 2 bits for buf_id_B
    #     buf_id_C_bits = format(self.buf_id_C, '02b')  # 2 bits for buf_id_C
    #     mem_addr_A_bits = format(self.mem_addr_A, '010b')  # 10 bits for mem_addr_A
    #     mem_addr_B_bits = format(self.mem_addr_B, '010b')  # 10 bits for mem_addr_B
    #     mem_addr_C_bits = format(self.mem_addr_C, '010b')  # 10 bits for mem_addr_C
    #     M_bits = format(self.M, '06b')  # 6 bits for M
    #     N_bits = format(self.N, '06b')  # 6 bits for N
    #     K_bits = format(self.K, '06b')  # 6 bits for K
    #     bitstream = function_type + buf_id_A_bits + buf_id_B_bits + buf_id_C_bits + mem_addr_A_bits + mem_addr_B_bits + \
    #                 mem_addr_C_bits + M_bits + N_bits + K_bits
    #     return bitstream
        
    def generate_bitstream(self):
        # Generate bitstream for the GEMM operation
        function_type = '0100'  # 4 bits for function type (GEMM operation)
        num_exec_bits = format(self.n, '010b')  # 6 bits for number of executions
        bitstream = function_type + num_exec_bits
        return bitstream



class DRAINSYSCommand:
    def __init__(self):
        print("you initiliazed the drain sys command")

    def generate_bitstream(self):
        # Generate bitstream for the GEMM operation
        function_type = '0101'  # 4 bits for function type (DRAINSYS command)
        num_exec_bits = format(0, '012b')  # 12 bits for nothing
        bitstream = function_type + num_exec_bits
        return bitstream
    
# Example usage
if __name__ == "__main__":
    gemm_op = GEMMCommand(3, 1, 2, 3, 0x100, 0x200, 0x300, 128, 128, 128)
    gemm_op.execute_command()
    print("Generated bitstream:", gemm_op.generate_bitstream())
    # Example usage
    store_cmd = StoreCommand(1, 0x200)
    store_cmd.execute_command()
    print("Generated bitstream:", store_cmd.generate_bitstream())


# Ideas for 
