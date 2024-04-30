module inst_reader #(
        parameter INST_WIDTH                    = 16,
        parameter INST_MEMORY_SIZE              = 1024,
        parameter LOG2_INST_MEMORY_SIZE         = 10,

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
        output          [OPCODE_WIDTH - 1: 0]   opcode,
        output          [BUF_ID_WIDTH - 1: 0]   buf_id,
        output          [MEM_LOC_WIDTH - 1: 0]  mem_loc,
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
        output  [LOG2_SRAM_BANK_DEPTH   -1: 0]  i_down_sram_rd_end_addr,

        input   [NUM_COL * ACCU_DATA_WIDTH-1: 0] o_down_rd_data
        // To controller //
);
        parameter IDLE   = 0;
        parameter STEADY = 1;
        parameter DRAIN  = 3;

        // Local variables //
        reg [INST_WIDTH - 1 : 0]                inst;
        reg [INST_WIDTH - 1 : 0]                inst_memory[0: INST_MEMORY_SIZE - 1];
        reg [DATA_WIDTH - 1 : 0]                A[0 : 1023];
        reg [LOG2_INST_MEMORY_SIZE - 1 : 0]     PC;
        integer                                 buffer_counter_A, buffer_counter_B, buffer_counter_C;
        integer                                 i, j;
        integer                                 m_left, m_top, start, finish;
        integer                                 delay_counter_LD, delay_counter_ST, delay_counter_GEMM, delay_counter_DRAINSYS;

        
        reg                                     inst_start = 0;
        reg inst_start_top = 0;
        reg inst_start_st = 0;

        reg                                     reg_i_top_wr_en = 0;
        reg  [LOG2_SRAM_BANK_DEPTH   -1: 0]     reg_i_top_wr_addr = 0;
        reg  [NUM_COL*DATA_WIDTH     -1: 0]     reg_i_top_wr_data = 0;
        
        reg                                     reg_i_left_wr_en;
        reg  [LOG2_SRAM_BANK_DEPTH   -1: 0]     reg_i_left_wr_addr = 0;
        reg  [NUM_ROW*DATA_WIDTH     -1: 0]     reg_i_left_wr_data = 0;
        
        reg                                     reg_i_down_rd_en = 0;
        reg  [LOG2_SRAM_BANK_DEPTH   -1: 0]     reg_i_down_rd_addr = 0;
        
        reg  [CTRL_WIDTH             -1: 0]     reg_i_ctrl_state = 0;
        reg  [LOG2_SRAM_BANK_DEPTH   -1: 0]     reg_i_top_sram_rd_start_addr = 0;
        reg  [LOG2_SRAM_BANK_DEPTH   -1: 0]     reg_i_top_sram_rd_end_addr = 0;
        reg  [LOG2_SRAM_BANK_DEPTH   -1: 0]     reg_i_left_sram_rd_start_addr = 0;
        reg  [LOG2_SRAM_BANK_DEPTH   -1: 0]     reg_i_left_sram_rd_end_addr = 0;
        reg  [LOG2_SRAM_BANK_DEPTH   -1: 0]     reg_i_down_sram_rd_start_addr = 0;
        reg  [LOG2_SRAM_BANK_DEPTH   -1: 0]     reg_i_down_sram_rd_end_addr = 0;
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
                delay_counter_LD = 0;
                delay_counter_ST = 0;
                delay_counter_GEMM = 0;
                delay_counter_DRAINSYS = 0;
                inst_start = 0;
      
                $readmemb("inst.txt", inst_memory); 
                $readmemb("data.txt", A);       
        end 

        assign opcode = inst[OPCODE_ARRAY_INDEX - 1    : BUF_ID_ARRAY_INDEX];
        assign buf_id = inst[BUF_ID_ARRAY_INDEX - 1    : MEM_LOC_ARRAY_INDEX];
        assign mem_loc = inst[MEM_LOC_ARRAY_INDEX - 1  : 0];
              
        always@(posedge clk or negedge rst_n)
        begin
                if (!rst_n)
                begin
                        inst <= 0;
                        // opcode <= 0;
                        // buf_id <= 0;
                        // mem_loc <= 0;     
                        inst_start <= 0;
                        inst_start_top <= 0;
                        inst_start_st <= 0;

                        PC <= 0;  
                        reg_i_ctrl_state = 0;      

                        reg_i_left_wr_en <= 0;
                        reg_i_left_wr_addr <= 0;
                end
                
                else
                begin
                        inst <= inst_memory[PC];
                        // opcode <= inst[OPCODE_ARRAY_INDEX - 1    : BUF_ID_ARRAY_INDEX];
                        // buf_id <= inst[BUF_ID_ARRAY_INDEX - 1    : MEM_LOC_ARRAY_INDEX];
                        // mem_loc <= inst[MEM_LOC_ARRAY_INDEX - 1  : 0];

                        case (opcode)
                                opcode_LD: 
                                begin
                                        if (buf_id == 2'b00)            // Load to left buffer
                                        begin
                                                if (inst_start == 0)
                                                begin
                                                        start <= mem_loc;
                                                        finish <= mem_loc + NUM_COL + NUM_ROW - 1;      // TODO: Change for D

                                                        m_left <= mem_loc;
                                                        reg_i_left_wr_en <= 1;
                                                        inst_start <= 1;
                                                        reg_i_left_wr_addr <= 1; 
                                                end 
                
                                                else 
                                                begin 
                                                        if (m_left < finish)
                                                        begin
                                                                reg_i_left_wr_addr <= reg_i_left_wr_addr + 1; 
                                                                for (j = 0; j < NUM_ROW; j = j + 1) 
                                                                        begin
                                                                                // Read value in A, send as data to SRAM
                                                                                // Data is stored as NUM_COL * DATA_WIDTH
                                                                                reg_i_left_wr_data[DATA_WIDTH * j +: DATA_WIDTH] <= A[((m_left - mem_loc - j) * NUM_ROW) + j + mem_loc];

                                                                                if (m_left < start + NUM_ROW - 1) //start = 0 here
                                                                                begin
                                                                                        if (j > m_left - start) 
                                                                                        begin 
                                                                                                reg_i_left_wr_data[DATA_WIDTH * j +: DATA_WIDTH] <= {DATA_WIDTH{1'b0}};
                                                                                        end
                                                                                end 
                                                                                
                                                                                else if (m_left > start + NUM_ROW - 1) 
                                                                                begin 
                                                                                        if (j < m_left - start - NUM_ROW - 1) 
                                                                                        begin
                                                                                                reg_i_left_wr_data[DATA_WIDTH * j +: DATA_WIDTH] <= {DATA_WIDTH{1'b0}};
                                                                                        end
                                                                                end
                                                                        end
                                                                        
                                                                        m_left <= m_left + 1; 
                                                        end
                                                        else if (m_left == finish && delay_counter_LD !== 2 && delay_counter_LD !== 3) 
                                                        begin 
                                                                // Set the correct start and end address of the left buffer (in this case, 0)
                                                                reg_i_left_sram_rd_start_addr <= 0;
                                                                reg_i_left_sram_rd_end_addr   <= NUM_COL + 1;
                                                                
                                                                // Disable write and clear wires
                                                                reg_i_left_wr_en   <= 0;
                                                                reg_i_left_wr_addr <= 0;

                                                                delay_counter_LD <= 2;
                                                        end 
                                                        else if(m_left == finish && delay_counter_LD == 2)         // TODO: Change for D
                                                        begin 
                                                                reg_i_left_wr_data <= 0;
                                                                PC <= PC + 1;

                                                                delay_counter_LD <= delay_counter_LD + 1;
                                                        end

                                                        else if(m_left == finish && delay_counter_LD == 3) 
                                                        begin 
                                                                inst_start <= 0;
                                                                delay_counter_LD <= 0;
                                                        end
                                                end            
                                        end

                                        else if (buf_id == 2'b01)       // Load to top buffer
                                        begin
                                                if (inst_start_top == 0)
                                                begin
                                                        start <= mem_loc;
                                                        finish <= mem_loc + NUM_COL + NUM_ROW - 1;      // TODO: Change for D

                                                        m_top <= mem_loc;
                                                        reg_i_top_wr_en <= 1;
                                                        inst_start_top <= 1;
                                                        reg_i_top_wr_addr <= 1;
                                                end 
                                                
                                                else 
                                                begin 
                                                        if (m_top < finish)
                                                        begin 
                                                                reg_i_top_wr_addr <= reg_i_top_wr_addr + 1;
                                                                for (j = 0; j < NUM_COL; j = j + 1) 
                                                                        begin

                                                                                reg_i_top_wr_data[DATA_WIDTH * j +: DATA_WIDTH] <= A[(((m_top - j - mem_loc) * NUM_COL) + j) +  mem_loc]; 
                                                                        
                                                                                if (m_top < start + NUM_COL - 1) 
                                                                                begin
                                                                                        if (j > m_top - start) 
                                                                                        begin 
                                                                                                reg_i_top_wr_data[DATA_WIDTH * j +: DATA_WIDTH] <= {DATA_WIDTH{1'b0}};
                                                                                        end
                                                                                end 
                                                                                
                                                                                else if (m_top > start + NUM_COL - 1) 
                                                                                begin 
                                                                                        if (j < m_top - start - NUM_COL - 1) 
                                                                                        begin
                                                                                                reg_i_top_wr_data[DATA_WIDTH * j +: DATA_WIDTH] <= {DATA_WIDTH{1'b0}};
                                                                                        end
                                                                                end
                                                                        end
                                                                
                                                                m_top <= m_top + 1;
                                                        end 
                                                        else if (m_top == finish && delay_counter_LD !== 2 && delay_counter_LD !== 3) 
                                                        begin 
                                                                // Set the correct start and end address of the top buffer (in this case, 0)
                                                                reg_i_top_sram_rd_start_addr <= 0; 
                                                                reg_i_top_sram_rd_end_addr   <= NUM_ROW + 1;
                                                                
                                                                // Disable write and clear wires
                                                                reg_i_top_wr_en   <= 0;
                                                                reg_i_top_wr_addr <= 0;

                                                                delay_counter_LD <= 2;
                                                        end 
                                                        else if(m_top == finish && delay_counter_LD == 2)       // TODO: Change for D
                                                        begin 
                                                                reg_i_top_wr_data <= 0;
                                                                PC <= PC + 1;

                                                                delay_counter_LD <= delay_counter_LD + 1;
                                                        end

                                                        else if(m_top == finish && delay_counter_LD == 3)       // TODO: Change for D
                                                        begin 
                                                                inst_start_top <= 0;
                                                                delay_counter_LD <= 0;
                                                        end
                                                end     
                                        end
                                end

                                opcode_ST:
                                begin
                                        if (inst_start_st == 0) 
                                        begin 
                                                reg_i_ctrl_state <= IDLE;
                                                inst_start_st <= inst_start_st + 1;
                                        end 
                                        
                                        else 
                                        begin 
                                                if (delay_counter_ST == 0) 
                                                begin 
                                                        // Set Address and enable 
                                                        reg_i_down_rd_en <= 0;
                                                        reg_i_down_rd_addr <= 0; 
                                                        delay_counter_ST <= delay_counter_ST + 1;
                                                end 
                                                
                                                else if (delay_counter_ST == 1) 
                                                begin 
                                                        reg_i_down_rd_en <= 1;
                                                        i <= 0; 
                                                        delay_counter_ST <= delay_counter_ST + 1;
                                                end 
                                                
                                                else if (i < NUM_ROW) 
                                                begin 
                                                        if(delay_counter_ST < NUM_ROW + 2) 
                                                        begin 
                                                                reg_i_down_rd_addr <= reg_i_down_rd_addr + 1;
                                                        end
                                                        
                                                        if (delay_counter_ST > 4)  
                                                        begin
                                                                if(delay_counter_ST == NUM_ROW + 2) begin 
                                                                       reg_i_down_rd_en <= 0 ;  
                                                                end
                                                                for (j = 0; j < NUM_COL; j = j + 1) 
                                                                        begin
                                                                                A[mem_loc + (j * NUM_COL + i)] <= o_down_rd_data[ACCU_DATA_WIDTH * j +: ACCU_DATA_WIDTH];
                                                                        end
                                                                i <= i + 1; 
                                                        end
                                                        delay_counter_ST <= delay_counter_ST + 1; 
                                                end 
                                                else if (reg_i_down_rd_addr == NUM_ROW && i == NUM_ROW) 
                                                begin 
                                                        $writememb("array_C_outs.txt", A);
                                                        reg_i_down_rd_en <= 0;
                                                        inst_start_st <= 0;
                                                        PC <= PC + 1;
                                                end
                                        end
                                end

                                opcode_GEMM: 
                                begin
                                        if (delay_counter_GEMM == 0)
                                        begin
                                                reg_i_ctrl_state <= STEADY;
                                                delay_counter_GEMM <= delay_counter_GEMM + 1;
                                        end

                                        else if (delay_counter_GEMM > 0 && delay_counter_GEMM < (2*NUM_ROW + NUM_COL)) //change counter value to include data depth
                                        begin
                                                delay_counter_GEMM <= delay_counter_GEMM + 1;
                                        end

                                        else if (delay_counter_GEMM == 2*NUM_ROW + NUM_COL)
                                        begin
                                                PC <= PC + 1;
                                                delay_counter_GEMM <= 0;
                                        end
                                end

                                opcode_DRAINSYS: 
                                begin
                                        if (delay_counter_DRAINSYS == 0)
                                        begin
                                                reg_i_ctrl_state <= DRAIN;
                                                delay_counter_DRAINSYS <= delay_counter_DRAINSYS + 1;
                                        end

                                        else if (delay_counter_DRAINSYS > 0 && delay_counter_DRAINSYS < (NUM_ROW + NUM_COL))
                                        begin
                                                delay_counter_DRAINSYS <= delay_counter_DRAINSYS + 1;
                                        end

                                        else if (delay_counter_DRAINSYS == NUM_ROW + NUM_COL)
                                        begin
                                                PC <= PC + 1;
                                                delay_counter_DRAINSYS <= 0;
                                        end
                                end

                                // default: PC = PC + 1;
                        endcase
                end
        end

        assign i_left_wr_en = reg_i_left_wr_en;
        assign i_left_wr_addr = reg_i_left_wr_addr;
        assign i_left_wr_data = reg_i_left_wr_data; 

        assign i_left_sram_rd_start_addr = reg_i_left_sram_rd_start_addr;
        assign i_left_sram_rd_end_addr = reg_i_left_sram_rd_end_addr; 
       
        assign i_top_wr_en = reg_i_top_wr_en; 
        assign i_top_wr_addr = reg_i_top_wr_addr;
        assign i_top_wr_data = reg_i_top_wr_data; 

        assign i_top_sram_rd_start_addr = reg_i_top_sram_rd_start_addr;
        assign i_top_sram_rd_end_addr = reg_i_top_sram_rd_end_addr; 

        assign i_ctrl_state = reg_i_ctrl_state;
        assign i_down_rd_en = reg_i_down_rd_en;
        assign i_down_rd_addr = reg_i_down_rd_addr;
        
endmodule