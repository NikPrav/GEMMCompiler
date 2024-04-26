module inst_reader #(
        parameter INST_WIDTH            = 16,
        parameter INST_MEMORY_SIZE      = 1024,
        parameter LOG2_INST_MEMORY_SIZE = 10,

        parameter OPCODE_WIDTH          = 4,
        parameter BUF_ID_WIDTH          = 2,
        parameter MEM_LOC_WIDTH         = 10,

        parameter MEM_LOC_ARRAY_INDEX   = MEM_LOC_WIDTH,
        parameter BUF_ID_ARRAY_INDEX    = MEM_LOC_ARRAY_INDEX + BUF_ID_WIDTH,
        parameter OPCODE_ARRAY_INDEX    = BUF_ID_ARRAY_INDEX + OPCODE_WIDTH,

        parameter opcode_LD             = 4'b0010,
        parameter opcode_ST             = 4'b0011,
        parameter opcode_GEMM           = 4'b0100,
        parameter opcode_DRAINSYS       = 4'b0101,

        parameter NUM_ROW               = 8,
        parameter NUM_COL               = 8,
        parameter DATA_WIDTH            = 8,
        parameter CTRL_WIDTH            = 4,
        parameter ACCU_DATA_WIDTH       = 32,
        parameter LOG2_SRAM_BANK_DEPTH  = 10,
        parameter SKEW_TOP_INPUT_EN     = 1,
        parameter SKEW_LEFT_INPUT_EN    = 1
)(
        input                                   clk,
        input                                   rst_n,

        // Instruction parts //
        output reg      [OPCODE_WIDTH - 1: 0]   opcode,
        output reg      [BUF_ID_WIDTH - 1: 0]   buf_id,
        output reg      [MEM_LOC_WIDTH - 1: 0]  mem_loc,
        // Instruction parts //


        // To controller //
        output                                  i_top_wr_en,
        output  [LOG2_SRAM_BANK_DEPTH   -1: 0]  i_top_wr_addr,
        output  [NUM_COL*DATA_WIDTH     -1: 0]  i_top_wr_data,
        
        output                                  i_left_wr_en,
        output  [LOG2_SRAM_BANK_DEPTH   -1: 0]  i_left_wr_addr,
        output  [NUM_ROW*DATA_WIDTH     -1: 0]  i_left_wr_data,
        
        output                                  i_down_rd_en,
        output  [LOG2_SRAM_BANK_DEPTH   -1: 0]  i_down_rd_addr,
        
        output  [CTRL_WIDTH             -1: 0]  i_ctrl_state,
        output  [LOG2_SRAM_BANK_DEPTH   -1: 0]  i_top_sram_rd_start_addr,
        output  [LOG2_SRAM_BANK_DEPTH   -1: 0]  i_top_sram_rd_end_addr,
        output  [LOG2_SRAM_BANK_DEPTH   -1: 0]  i_left_sram_rd_start_addr,
        output  [LOG2_SRAM_BANK_DEPTH   -1: 0]  i_left_sram_rd_end_addr,
        output  [LOG2_SRAM_BANK_DEPTH   -1: 0]  i_down_sram_rd_start_addr,
        output  [LOG2_SRAM_BANK_DEPTH   -1: 0]  i_down_sram_rd_end_addr
        // To controller //
);

        // Local variables //
        reg [INST_WIDTH - 1 : 0]                inst;
        reg [INST_WIDTH - 1 : 0]                inst_memory[INST_MEMORY_SIZE - 1 : 0];
        reg [LOG2_INST_MEMORY_SIZE - 1 : 0]     PC;
        // Local variables //

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
                //         // Buffer address counter x3 (i for each buf) 
                //         // Send read enable to on-chip SRAM A, get output from that. 
                //         // Global counter register for i; need to reset after one fill: buff clear / make a shift reg 
                //         // PC++  
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