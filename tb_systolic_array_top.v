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
    parameter                                       NUM_ROW                             = 4  ;
    parameter                                       NUM_COL                             = 4  ;
    parameter                                       DATA_WIDTH                          = 8  ;
    parameter                                       ACCU_DATA_WIDTH                     = 32 ;
    parameter                                       OUT_DATA_WIDTH                      = ACCU_DATA_WIDTH ;
    parameter                                       LOG2_SRAM_BANK_DEPTH                = 5 ;
    parameter                                       CTRL_WIDTH                          = 4 ;

    reg                                             clk                                 = 0 ;
    reg                                             rst_n                               = 0 ;
    reg                                             r_i_top_wr_en                       = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_top_wr_addr                     = 0 ;
    reg     [NUM_COL*DATA_WIDTH         -1: 0]      r_i_top_wr_data                     = 0 ;
    reg                                             r_i_left_wr_en                      = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_left_wr_addr                    = 0 ;
    reg     [NUM_ROW*DATA_WIDTH         -1: 0]      r_i_left_wr_data                    = 0 ;
    reg                                             r_i_down_rd_en                      = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_down_rd_addr                    = 0 ;
    wire    [NUM_COL*OUT_DATA_WIDTH     -1: 0]      w_o_down_rd_data                        ;
    reg     [CTRL_WIDTH                 -1: 0]      r_i_ctrl_state                      = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_top_sram_rd_start_addr          = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_top_sram_rd_end_addr            = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_left_sram_rd_start_addr         = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_left_sram_rd_end_addr           = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_down_sram_rd_start_addr         = 0 ;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_down_sram_rd_end_addr           = 0 ;
    // Changed the following
    initial begin
        rst_n = 0;
        #(`PERIOD)
        rst_n = 1;

        $stop;
    end


    systolic_array_top#(
        .NUM_ROW                    (NUM_ROW                        ),
        .NUM_COL                    (NUM_COL                        ),
        .DATA_WIDTH                 (DATA_WIDTH                     ),
        .ACCU_DATA_WIDTH            (ACCU_DATA_WIDTH                ),
        .LOG2_SRAM_BANK_DEPTH       (LOG2_SRAM_BANK_DEPTH           )
    )inst_sa_datapath(
        .clk                        (clk                            ),
        .rst_n                      (rst_n                          ),
        .i_top_wr_en                (r_i_top_wr_en                  ),
        .i_top_wr_data              (r_i_top_wr_data                ),
        .i_top_wr_addr              (r_i_top_wr_addr                ),
        .i_left_wr_en               (r_i_left_wr_en                 ),
        .i_left_wr_data             (r_i_left_wr_data               ),
        .i_left_wr_addr             (r_i_left_wr_addr               ),
        .i_down_rd_en               (r_i_down_rd_en                 ),
        .i_down_rd_addr             (r_i_down_rd_addr               ),
        .o_down_rd_data             (w_o_down_rd_data               ),
        .i_ctrl_state               (r_i_ctrl_state                 ),
        .i_top_sram_rd_start_addr   (r_i_top_sram_rd_start_addr     ),
        .i_top_sram_rd_end_addr     (r_i_top_sram_rd_end_addr       ),
        .i_left_sram_rd_start_addr  (r_i_left_sram_rd_start_addr    ),
        .i_left_sram_rd_end_addr    (r_i_left_sram_rd_end_addr      ),
        .i_down_sram_rd_start_addr  (r_i_down_sram_rd_start_addr    ),
        .i_down_sram_rd_end_addr    (r_i_down_sram_rd_end_addr      )
    );

    // Free running clk
    always #(`PERIOD/2) clk = ~clk;
endmodule

