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


module tb_systolic_array_top();
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
    parameter WARMUP = 1;
    parameter STEADY = 2;
    parameter DRAIN  = 3;
    
    // Changed the following: Add temp memories for
    reg [DATA_WIDTH-1: 0] A[0:15];
    reg [DATA_WIDTH-1: 0] B[0:15];
    
    integer  i, j;
    
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
        
        for(i = 0; i <  NUM_ROW; i = i + 1)
        begin
            @(posedge  clk);
            // Set the appropriate address in the SRAM
            r_i_left_wr_addr = i;
            $display("addr   = %d\n", r_i_left_wr_addr);
            
            for (j = 0; j < NUM_COL; j = j + 1)
            begin
                // Read value in A, send as data to SRAM
                // Data is stored as NUM_COL * DATA_WIDTH
                r_i_left_wr_data[DATA_WIDTH * j +: DATA_WIDTH] = A[i + j * NUM_COL];
                $display("data, i, j                           = %d, %d, %d\n", A[i + j * NUM_COL], i, j);
            end
        end
        
        @(posedge  clk);//#(`PERIOD * 2)
        // Disable write and clear wires
        r_i_left_wr_en   = 0;
        r_i_left_wr_data = 0;
        r_i_left_wr_addr = 0;
        
        
        // ------------------------------------------------ Write data into the TOP BUFFER
        
        // Enable
        r_i_top_wr_en = 1;
        
        // Set the correct start and end address of the top buffer (in this case, 0)
        r_i_top_sram_rd_start_addr = 5'd0;
        r_i_top_sram_rd_end_addr   = 5'd8;
        
        for(i = 0; i <  NUM_COL; i = i + 1) begin
            
            @(posedge  clk);

            // Set the appropriate address in the SRAM
            r_i_top_wr_addr = i + 3;        
            
            for (j = 0; j < NUM_ROW; j = j + 1) begin
                // Read value in A, send as data to SRAM
                // Data is stored as NUM_COL * DATA_WIDTH
                r_i_top_wr_data[DATA_WIDTH * j +: DATA_WIDTH] = B[i + j * NUM_ROW];
            end
        end

        // Disable write and clear wires
        r_i_top_wr_en   = 0;
        r_i_top_wr_addr = 0;
        r_i_top_wr_data = 0;
        
        
        // ------------------------------------------------
        // ------------------------------------------------ WARMUP stage
        // ------------------------------------------------
        
        // ------------------------------------------------ Fill from the TOP BUFFER
        
        r_i_ctrl_state = WARMUP;
        
        // Let the filling happen
        #(`PERIOD * 10)
        
        // ------------------------------------------------
        // ------------------------------------------------ STEADY stage
        // ------------------------------------------------
        
        // Set the correct start and end address of the left buffer (in this case, 0)
        r_i_left_sram_rd_start_addr = 5'd0;
        r_i_left_sram_rd_end_addr   = 5'd4;
        
        // ------------------------------------------------ Fill from the TOP BUFFER
        
        r_i_ctrl_state = STEADY;
        
        
        $stop;
    end
    
    
    systolic_array_top#(
    .NUM_ROW                    (NUM_ROW),
    .NUM_COL                    (NUM_COL),
    .DATA_WIDTH                 (DATA_WIDTH),
    .ACCU_DATA_WIDTH            (ACCU_DATA_WIDTH),
    .LOG2_SRAM_BANK_DEPTH       (LOG2_SRAM_BANK_DEPTH),
    .SKEW_TOP_INPUT_EN (0)
    )inst_sa_datapath(
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
    
    // Free running clk
    always #(`PERIOD/2) clk = ~clk;
endmodule
