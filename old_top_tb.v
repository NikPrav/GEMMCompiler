`timescale 1ns/1ps

/*
 Top Module:  tb_systolic_array_top
 Data:        DATA_WIDTH is the width of input data -> OUT_WORD_SIZE is the width of output data.
 Format:      OUT_WORD_SIZE = DATA_WIDTH << 1; beacuse multiplication happen inside
 Timing:      Sequential Logic
 Reset:       Synchronized Reset [High negedge rst_n]
 Dummy Data:  {DATA_WIDTH{1'b0}}
 
 Function:    Output Stationary.
 [1*IWS+:IWS]   [3*IWS+:IWS]
 weights[0*IWS+:IWS] |[2*IWS+:IWS] |
 |      |      |      |
 v      v      v      v
 iActs[0*IWS+:IWS]   -->|¯¯¯|--|¯¯¯|--|¯¯¯|--|¯¯¯|
 |___|  |___|  |___|  |___|
 |      |      |      |
 i_data[1*IWS+:IWS]   -->|¯¯¯|--|¯¯¯|--|¯¯¯|--|¯¯¯|
 |___|  |___|  |___|  |___|
 |      |      |      |
 ...              -->|¯¯¯|--|¯¯¯|--|¯¯¯|--|¯¯¯|
 |___|  |___|  |___|  |___|
 |      |      |      |
 i_data[NUM_ROW*IWS+:IWS]-->|¯¯¯|--|¯¯¯|--|¯¯¯|--|¯¯¯|
 |___|  |___|  |___|  |___|
 |      |      |      |
 v      v      v      v
 o_data o_data o_data o_data
 [0*IWS+:IWS]               [NUM_ROW*IWS+:IWS]
 
 Every node has an output value;
 */

`define PERIOD 10


module old_top_tb();
    parameter                                       NUM_ROW              = 4  ;
    parameter                                       NUM_COL              = 4  ;
    parameter                                       DATA_WIDTH           = 8  ;
    parameter                                       ACCU_DATA_WIDTH      = 32 ;
    parameter                                       OUT_DATA_WIDTH       = ACCU_DATA_WIDTH ;
    parameter                                       LOG2_SRAM_BANK_DEPTH = 5 ;
    parameter                                       CTRL_WIDTH           = 4 ;
    
    reg                                             clk              = 0 ;
    reg                                             rst_n            = 0 ;
    reg                                             r_i_top_wr_en    = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_top_wr_addr  = 0 ;
    reg     [NUM_COL*DATA_WIDTH         -1: 0]      r_i_top_wr_data  = 0 ;
    reg                                             r_i_left_wr_en   = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_left_wr_addr = 0 ;
    reg     [NUM_ROW*DATA_WIDTH         -1: 0]      r_i_left_wr_data = 0 ;
    reg                                             r_i_down_rd_en   = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_down_rd_addr = 0 ;
    wire    [NUM_COL*OUT_DATA_WIDTH     -1: 0]      w_o_down_rd_data ;
    reg     [CTRL_WIDTH                 -1: 0]      r_i_ctrl_state              = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_top_sram_rd_start_addr  = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_top_sram_rd_end_addr    = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_left_sram_rd_start_addr = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_left_sram_rd_end_addr   = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_down_sram_rd_start_addr = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_down_sram_rd_end_addr   = 0 ;
    
    parameter IDLE   = 0;
    parameter STEADY = 1;
    parameter DRAIN  = 3;
    
    // Changed the following: Add temp memories for
    reg [DATA_WIDTH-1: 0] A[0:15];
    reg [DATA_WIDTH-1: 0] B[0:15];
    
    integer  i, j;
    integer m_left, m_top;

    // Inst_reader variables //
    parameter INST_WIDTH            = 16;
    parameter INST_MEMORY_SIZE      = 4;
    parameter LOG2_INST_MEMORY_SIZE = 2;

    parameter OPCODE_WIDTH          = 4;
    parameter BUF_ID_WIDTH          = 2;
    parameter MEM_LOC_WIDTH         = 10;

    parameter MEM_LOC_ARRAY_INDEX   = MEM_LOC_WIDTH;
    parameter BUF_ID_ARRAY_INDEX    = MEM_LOC_ARRAY_INDEX + BUF_ID_WIDTH;
    parameter OPCODE_ARRAY_INDEX    = BUF_ID_ARRAY_INDEX + OPCODE_WIDTH;

    parameter opcode_LD             = 4'b0010;
    parameter opcode_ST             = 4'b0011;
    parameter opcode_GEMM           = 4'b0100;
    parameter opcode_DRAINSYS       = 4'b0101;

    wire [OPCODE_WIDTH - 1: 0]   opcode;
    wire [BUF_ID_WIDTH - 1: 0]   buf_id;
    wire [MEM_LOC_WIDTH - 1: 0]  mem_loc;
    // Inst_reader variables //
    
    initial
    begin
        rst_n = 0;
        #(`PERIOD)
        rst_n = 1;
        
        $readmemb("array_A_fi.txt", A);
        $readmemb("array_B_fi.txt", B);
        
        // ------------------------------------------------
        // ------------------------------------------------ Set the operation state to IDLE
        // ------------------------------------------------
        
        r_i_ctrl_state = IDLE;
        
        // ------------------------------------------------ Write data into the LEFT BUFFER
        
        // Enable
        r_i_left_wr_en = 1;

        @(posedge  clk);

        for (m_left = 0; m_left < NUM_COL + NUM_ROW - 1; m_left = m_left + 1) begin 
            
            r_i_left_wr_addr = m_left;   
            @(posedge  clk);

            for (j = 0; j < NUM_ROW; j = j + 1) begin
                // Read value in B, send as data to SRAM
                // Data is stored as NUM_COL * DATA_WIDTH
                r_i_left_wr_data[DATA_WIDTH * j +: DATA_WIDTH] = A[((m_left - j) * NUM_ROW) + j];

                if (m_left < NUM_ROW - 1) begin
                    if (j > m_left) begin 
                        r_i_left_wr_data[DATA_WIDTH * j +: DATA_WIDTH] = {DATA_WIDTH{1'b0}};
                    end
                end else if (m_left > NUM_ROW - 1) begin 
                    if (j < m_left - NUM_ROW - 1) begin
                        r_i_left_wr_data[DATA_WIDTH * j +: DATA_WIDTH] = {DATA_WIDTH{1'b0}};
                    end
                end
            end
        end

        // Set the correct start and end address of the left buffer (in this case, 0)
        r_i_left_sram_rd_start_addr = 5'd0;
        r_i_left_sram_rd_end_addr   = 5'd4;
        
        @(posedge  clk);//#(`PERIOD * 2)
        
        // Disable write and clear wires
        r_i_left_wr_en   = 0;
        r_i_left_wr_addr = 0;
        @(posedge  clk);
        r_i_left_wr_data = 0;
        @(posedge  clk);      
        
        // ------------------------------------------------ Write data into the TOP BUFFER
        
        // Enable
        r_i_top_wr_en = 1;

        for (m_top = 0; m_top < NUM_COL + NUM_ROW - 1; m_top = m_top + 1) begin 
            
            r_i_top_wr_addr = m_top;   
            @(posedge  clk);

            for (j = 0; j < NUM_COL; j = j + 1) begin
                // Read value in B, send as data to SRAM
                // Data is stored as NUM_COL * DATA_WIDTH
                r_i_top_wr_data[DATA_WIDTH * j +: DATA_WIDTH] = B[((m_top - j) * NUM_COL) + j];

                if (m_top < NUM_COL - 1) begin
                    if (j > m_top) begin 
                        r_i_top_wr_data[DATA_WIDTH * j +: DATA_WIDTH] = {DATA_WIDTH{1'b0}};
                    end
                end else if (m_top > NUM_COL - 1) begin 
                    if (j < m_top - NUM_COL - 1) begin
                        r_i_top_wr_data[DATA_WIDTH * j +: DATA_WIDTH] = {DATA_WIDTH{1'b0}};
                    end
                end
            end
        end
        
        // Set the correct start and end address of the top buffer (in this case, 0)
        r_i_top_sram_rd_start_addr = 5'd0;
        r_i_top_sram_rd_end_addr   = 5'd4;
    
        @(posedge  clk);
        
        // Disable write and clear wires
        r_i_top_wr_en   = 0;
        r_i_top_wr_addr = 0;
        @(posedge  clk);   
        r_i_top_wr_data = 0;  
        @(posedge  clk);
        
        // ------------------------------------------------
        // ------------------------------------------------ WARMUP stage
        // ------------------------------------------------
        
        // ------------------------------------------------ Fill from the TOP BUFFER
        
        r_i_ctrl_state = STEADY;
        
        // Let the filling happen
        @(posedge  clk);
        @(posedge  clk);
        @(posedge  clk);
        @(posedge  clk);
        @(posedge  clk);
        @(posedge  clk);
        @(posedge  clk);
        @(posedge  clk);
        @(posedge  clk);
        @(posedge  clk);

        r_i_ctrl_state = DRAIN;

        @(posedge  clk);
        @(posedge  clk);
        @(posedge  clk);
        @(posedge  clk);
        @(posedge  clk);
        @(posedge  clk);
        
        // ------------------------------------------------
        // ------------------------------------------------ STEADY stage
        // ------------------------------------------------
        
        
        
        // ------------------------------------------------ Fill from the TOP BUFFER
        

        $stop;
    end
    
    
    systolic_array_top#(
    .NUM_ROW                    (NUM_ROW),
    .NUM_COL                    (NUM_COL),
    .DATA_WIDTH                 (DATA_WIDTH),
    .ACCU_DATA_WIDTH            (ACCU_DATA_WIDTH),
    .LOG2_SRAM_BANK_DEPTH       (LOG2_SRAM_BANK_DEPTH),
    .SKEW_TOP_INPUT_EN (1) 
    )inst_sa_array_top(
    .clk                        (clk),
    .rst_n                      (rst_n),
    .i_top_wr_en                (r_i_top_wr_en),
    .i_top_wr_data              (r_i_top_wr_data),
    .i_top_wr_addr              (r_i_top_wr_addr),
    .i_left_wr_en               (r_i_left_wr_en),
    .i_left_wr_data             (r_i_left_wr_data),
    .i_left_wr_addr             (r_i_left_wr_addr),
    .i_down_rd_en               (r_i_down_rd_en),
    .i_down_rd_addr             (r_i_down_rd_addr),
    .o_down_rd_data             (w_o_down_rd_data),
    .i_ctrl_state               (r_i_ctrl_state),
    .i_top_sram_rd_start_addr   (r_i_top_sram_rd_start_addr),
    .i_top_sram_rd_end_addr     (r_i_top_sram_rd_end_addr),
    .i_left_sram_rd_start_addr  (r_i_left_sram_rd_start_addr),
    .i_left_sram_rd_end_addr    (r_i_left_sram_rd_end_addr),
    .i_down_sram_rd_start_addr  (r_i_down_sram_rd_start_addr),
    .i_down_sram_rd_end_addr    (r_i_down_sram_rd_end_addr)
    );

    inst_reader #(
        .INST_WIDTH             (INST_WIDTH),
        .INST_MEMORY_SIZE       (INST_MEMORY_SIZE),
        .LOG2_INST_MEMORY_SIZE  (LOG2_INST_MEMORY_SIZE),
        .OPCODE_WIDTH           (OPCODE_WIDTH),
        .BUF_ID_WIDTH           (BUF_ID_WIDTH),
        .MEM_LOC_WIDTH          (MEM_LOC_WIDTH),

        .OPCODE_ARRAY_INDEX     (OPCODE_ARRAY_INDEX),
        .BUF_ID_ARRAY_INDEX     (BUF_ID_ARRAY_INDEX),
        .MEM_LOC_ARRAY_INDEX    (MEM_LOC_ARRAY_INDEX),

        .opcode_LD              (opcode_LD),
        .opcode_ST              (opcode_ST),
        .opcode_GEMM            (opcode_GEMM),
        .opcode_DRAINSYS        (opcode_DRAINSYS)
    )inst_reader_in_tb(
        .clk                    (clk),
        .opcode                 (opcode),
        .buf_id                 (buf_id),
        .mem_loc                (mem_loc)
);
    
    // Free running clk
    always #(`PERIOD/2) clk = ~clk;
endmodule
