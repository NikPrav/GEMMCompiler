module inst_reader #(
        parameter INST_WIDTH                    = 16,
        parameter INST_MEMORY_SIZE              = 1024,
        parameter LOG2_INST_MEMORY_SIZE         = 10,
        parameter A_OFFSET                      = 1024,
        parameter B_OFFSET                      = 2048,
        parameter C_OFFSET                      = 3072,

        parameter OPCODE_WIDTH                  = 4,
        parameter BUF_ID_WIDTH                  = 2,
        parameter MEM_LOC_WIDTH                 = 10,

        parameter MEM_LOC_ARRAY_INDEX           = MEM_LOC_WIDTH,
        parameter BUF_ID_ARRAY_INDEX            = MEM_LOC_ARRAY_INDEX + BUF_ID_WIDTH,
        parameter OPCODE_ARRAY_INDEX            = BUF_ID_ARRAY_INDEX + OPCODE_WIDTH,

        parameter opcode_LD                     = 4'b0010,
        parameter opcode_ST                     = 4'b0011,
        parameter opcode_GEMM                   = 4'b0100,
        parameter opcode_DRAINSYS               = 4'b0101,

        parameter NUM_ROW                       = 8,
        parameter NUM_COL                       = 8,
        parameter DATA_WIDTH                    = 8,
        parameter CTRL_WIDTH                    = 4,
        parameter ACCU_DATA_WIDTH               = 32,
        parameter LOG2_SRAM_BANK_DEPTH          = 10,
        parameter SKEW_TOP_INPUT_EN             = 1,
        parameter SKEW_LEFT_INPUT_EN            = 1
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
        integer                                 buffer_counter_A, buffer_counter_B, buffer_counter_C;
        integer                                 i, j;
        integer                                 m_left, m_top, start, finish;
        // Local variables //

        initial 
        begin
                PC = 0;
                buffer_counter_A = 0;
                buffer_counter_B = 0;
                buffer_counter_C = 0;
                i = 0;
                j = 0;
                m_left = 0;
                m_top = 0;
                
                $readmemb("inst.txt", inst_memory);        
        end

        always@(posedge clk)
        begin
                inst = inst_memory[PC];
                opcode = inst[OPCODE_ARRAY_INDEX - 1    : BUF_ID_ARRAY_INDEX];
                buf_id = inst[BUF_ID_ARRAY_INDEX - 1    : MEM_LOC_ARRAY_INDEX];
                mem_loc = inst[MEM_LOC_ARRAY_INDEX - 1  : 0];
                PC = PC + 1;

                case (opcode)
                        opcode_LD: 
                        begin
                                if (buf_id == 2'b00)            // Load to left buffer
                                begin
                                        start = A_OFFSET + mem_loc;
                                        finish = start + NUM_COL + NUM_ROW - 1;
                                        r_i_left_wr_en = 1;

                                        @(posedge clk);

                                        for (m_left = start; m_left < finish; m_left = m_left + 1) 
                                        begin 
                                                r_i_left_wr_addr = m_left;   
                                                @(posedge  clk);

                                                for (j = 0; j < NUM_ROW; j = j + 1) 
                                                begin
                                                        // Read value in A, send as data to SRAM
                                                        // Data is stored as NUM_COL * DATA_WIDTH
                                                        r_i_left_wr_data[DATA_WIDTH * j +: DATA_WIDTH] = A[((m_left - j) * NUM_ROW) + j];

                                                        if (m_left < NUM_ROW - 1) 
                                                        begin
                                                                if (j > m_left) 
                                                                begin 
                                                                        r_i_left_wr_data[DATA_WIDTH * j +: DATA_WIDTH] = {DATA_WIDTH{1'b0}};
                                                                end
                                                        end 
                                                        
                                                        else if (m_left > NUM_ROW - 1) 
                                                        begin 
                                                                if (j < m_left - NUM_ROW - 1) 
                                                                begin
                                                                        r_i_left_wr_data[DATA_WIDTH * j +: DATA_WIDTH] = {DATA_WIDTH{1'b0}};
                                                                end
                                                        end
                                                end
                                        end

                                        // Set the correct start and end address of the left buffer (in this case, 0)
                                        r_i_left_sram_rd_start_addr = start;
                                        r_i_left_sram_rd_end_addr   = finish;
                                        
                                        @(posedge clk);        //#(`PERIOD * 2)
                                        
                                        // Disable write and clear wires
                                        r_i_left_wr_en   = 0;
                                        r_i_left_wr_addr = 0;
                                        @(posedge clk);
                                        r_i_left_wr_data = 0;
                                        @(posedge clk);                     
                                end

                                else if (buf_id == 2'b01)       // Load to top buffer
                                begin
                                        start = B_OFFSET + mem_loc;
                                        finish = start + NUM_COL + NUM_ROW - 1;
                                        r_i_top_wr_en = 1;

                                        for (m_top = start; m_top < finish; m_top = m_top + 1) 
                                        begin 
                                                r_i_top_wr_addr = m_top;   
                                                @(posedge clk);

                                                for (j = 0; j < NUM_COL; j = j + 1) 
                                                begin
                                                        // Read value in B, send as data to SRAM
                                                        // Data is stored as NUM_COL * DATA_WIDTH
                                                        r_i_top_wr_data[DATA_WIDTH * j +: DATA_WIDTH] = A[((m_top - j) * NUM_COL) + j];

                                                        if (m_top < NUM_COL - 1) 
                                                        begin
                                                                if (j > m_top) 
                                                                begin 
                                                                        r_i_top_wr_data[DATA_WIDTH * j +: DATA_WIDTH] = {DATA_WIDTH{1'b0}};
                                                                end
                                                        end 
                                                        
                                                        else if (m_top > NUM_COL - 1) 
                                                        begin 
                                                                if (j < m_top - NUM_COL - 1) 
                                                                begin
                                                                        r_i_top_wr_data[DATA_WIDTH * j +: DATA_WIDTH] = {DATA_WIDTH{1'b0}};
                                                                end
                                                        end
                                                end
                                        end
                                        
                                        // Set the correct start and end address of the top buffer (in this case, 0)
                                        r_i_top_sram_rd_start_addr = start;
                                        r_i_top_sram_rd_end_addr   = finish;
                                
                                        @(posedge clk);
                                        
                                        // Disable write and clear wires
                                        r_i_top_wr_en   = 0;
                                        r_i_top_wr_addr = 0;
                                        @(posedge clk);   
                                        r_i_top_wr_data = 0;  
                                        @(posedge clk);
                                end
                                PC = PC + 1;
                        end

                        opcode_ST: // TODO: Find store address
                        begin
                                r_i_ctrl_state = IDLE;

                                // Set Address and enable 
                                r_i_down_rd_en = 0;
                                r_i_down_rd_addr = 0;

                                @(posedge clk);
                                r_i_down_rd_en = 1;

                                // Read each row of the buffer output and transform into columnwsie
                                for (i = 0; i < NUM_ROW; i = i + 1) 
                                begin 
                                        r_i_down_rd_addr = i + 1;
                                        @(posedge clk);

                                        for (j = 0; j < NUM_COL; j = j + 1) 
                                        begin
                                                A[j * NUM_ROW + i] = w_o_down_rd_data[OUT_DATA_WIDTH * j +: OUT_DATA_WIDTH];
                                        end
                                end

                                @(posedge clk);
                                r_i_down_rd_en = 0;
                                PC = PC + 1;
                        end

                        opcode_GEMM: 
                        begin
                                r_i_ctrl_state = STEADY;
        
                                // Let the filling happen
                                @(posedge clk);
                                @(posedge clk);
                                @(posedge clk);
                                @(posedge clk);
                                @(posedge clk);
                                @(posedge clk);
                                @(posedge clk);
                                @(posedge clk);
                                @(posedge clk);
                                @(posedge clk);
                                @(posedge clk);
                                PC = PC + 1;
                        end

                        opcode_DRAINSYS: 
                        begin
                                r_i_ctrl_state = DRAIN;

                                @(posedge clk);
                                @(posedge clk);
                                @(posedge clk);
                                @(posedge clk);
                                @(posedge clk);
                                @(posedge clk);
                                PC = PC + 1;
                        end

                        default:
                endcase

        
        end
        
endmodule