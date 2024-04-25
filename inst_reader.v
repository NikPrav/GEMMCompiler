module inst_reader #(
        parameter INST_WIDTH            = 16,
        parameter INST_MEMORY_SIZE      = 1024,

        parameter OPCODE_WIDTH  = 4,
        parameter BUF_ID_WIDTH  = 2,
        parameter MEM_LOC_WIDTH = 10,

        parameter MEM_LOC_ARRAY_INDEX   = MEM_LOC_WIDTH,
        parameter BUF_ID_ARRAY_INDEX    = MEM_LOC_ARRAY_INDEX + BUF_ID_WIDTH,
        parameter OPCODE_ARRAY_INDEX    = BUF_ID_ARRAY_INDEX + OPCODE_WIDTH,

        parameter opcode_LD             = 4'b0010,
        parameter opcode_ST             = 4'b0011,
        parameter opcode_GEMM           = 4'b0100,
        parameter opcode_DRAINSYS       = 4'b0101 
)(
        input clk,
        output reg      [OPCODE_WIDTH - 1: 0]   opcode,
        output reg      [BUF_ID_WIDTH - 1: 0]   buf_id,
        output reg      [MEM_LOC_WIDTH - 1: 0]  mem_loc
);

        // Local variables
        reg [INST_WIDTH - 1 : 0] inst;
        reg [INST_WIDTH - 1 : 0] inst_memory[INST_MEMORY_SIZE - 1 : 0];
        integer PC;

        // Functionality
        initial 
        begin
                PC = 0;
                $readmemb("inst.txt", inst_memory);        
        end

        always@(posedge clk)
        begin
                inst = inst_memory[PC];
                opcode = inst[OPCODE_ARRAY_INDEX - 1    : BUF_ID_ARRAY_INDEX];
                buf_id = inst[BUF_ID_ARRAY_INDEX - 1    : MEM_LOC_ARRAY_INDEX];
                mem_loc = inst[MEM_LOC_ARRAY_INDEX - 1  : 0];
                PC = PC + 1;

                // if (opcode == opcode_LD)
                // begin
                // end
                // else if (opcode == opcode_ST)
                // begin
                // end
                // else if (opcode == opcode_GEMM)
                // begin
                // end
                // else if (opcode == opcode_DRAINSYS)
                // begin
                // end
        end

endmodule