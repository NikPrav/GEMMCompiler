module systolic_array_top #(
        parameter NUM_ROW = 8,
        parameter NUM_COL = 8,
        parameter DATA_WIDTH = 8,
        parameter ACCU_DATA_WIDTH = 32,
        parameter LOG2_SRAM_BANK_DEPTH = 10,
        parameter SKEW_TOP_INPUT_EN = 1,
        parameter SKEW_LEFT_INPUT_EN = 1
)(
        clk,
        rst_n,
        i_top_wr_en,
        i_top_wr_data,
        i_top_wr_addr,
        i_left_wr_en,
        i_left_wr_data,
        i_left_wr_addr,
        i_down_rd_en,
        i_down_rd_addr,
        o_down_rd_data,
        i_ctrl_state,
        i_top_sram_rd_start_addr,
        i_top_sram_rd_end_addr,
        i_left_sram_rd_start_addr,
        i_left_sram_rd_end_addr,
        i_down_sram_rd_start_addr,
        i_down_sram_rd_end_addr
);
        // Inputs and Outputs //
        input                                                       clk;
        input                                                       rst_n;
        input                                                       i_top_wr_en    ;
        input   [LOG2_SRAM_BANK_DEPTH   -1: 0]                      i_top_wr_addr  ;
        input   [NUM_COL*DATA_WIDTH     -1: 0]                      i_top_wr_data  ;
    
        input                                                       i_left_wr_en   ;
        input   [LOG2_SRAM_BANK_DEPTH   -1: 0]                      i_left_wr_addr ;
        input   [NUM_ROW*DATA_WIDTH     -1: 0]                      i_left_wr_data ;

        input                                                       i_down_rd_en   ;
        input   [LOG2_SRAM_BANK_DEPTH   -1: 0]                      i_down_rd_addr ;
        output  [NUM_COL*OUT_DATA_WIDTH -1: 0]                      o_down_rd_data ;

        input   [CTRL_WIDTH             -1: 0]                      i_ctrl_state              ;
        input   [LOG2_SRAM_BANK_DEPTH   -1: 0]                      i_top_sram_rd_start_addr  ;
        input   [LOG2_SRAM_BANK_DEPTH   -1: 0]                      i_top_sram_rd_end_addr    ;
        input   [LOG2_SRAM_BANK_DEPTH   -1: 0]                      i_left_sram_rd_start_addr ;
        input   [LOG2_SRAM_BANK_DEPTH   -1: 0]                      i_left_sram_rd_end_addr   ;
        input   [LOG2_SRAM_BANK_DEPTH   -1: 0]                      i_down_sram_rd_start_addr ;
        input   [LOG2_SRAM_BANK_DEPTH   -1: 0]                      i_down_sram_rd_end_addr   ;
        // Inputs and Outputs //


        // Local Variables //
        wire    [DATA_WIDTH             : 0]                      w_i_top_wr_data     [0 : NUM_COL-1] ; // Changed to DATAWIDTH+1
        wire    [DATA_WIDTH             : 0]                      w_o_top_rd_data     [0 : NUM_COL-1] ; // Changed to DATAWIDTH+1
        wire    [DATA_WIDTH             -1: 0]                      w_i_left_wr_data    [0 : NUM_ROW-1] ;
        wire    [DATA_WIDTH             -1: 0]                      w_o_left_rd_data    [0 : NUM_ROW-1] ;
        wire                                                        w_top_rd_wr_en_from_ctrl            ;   // should this be array
        wire    [LOG2_SRAM_BANK_DEPTH   -1: 0]                      w_top_rd_wr_addr_from_ctrl          ;
        wire                                                        w_left_rd_wr_en_from_ctrl           ;   // should this be array
        wire    [LOG2_SRAM_BANK_DEPTH   -1: 0]                      w_left_rd_wr_addr_from_ctrl         ;
        wire    [NUM_COL                -1: 0]                      w_down_rd_wr_en_from_ctrl           ;
        wire    [LOG2_SRAM_BANK_DEPTH   -1: 0]                      w_down_rd_wr_addr_from_ctrl         ;
        wire    [NUM_COL                -1: 0]                      w_o_valid_down_from_sa              ;
        wire    [NUM_COL*OUT_DATA_WIDTH -1: 0]                      w_o_data_down_from_sa               ;
        wire    [NUM_COL                -1: 0]                      w_top_valid_from_ctrl       ;
        wire    [NUM_ROW                -1: 0]                      w_left_valid_from_ctrl      ;

        reg     [NUM_COL                    -1: 0]  r_i_cmd_top                 ;
        reg     [NUM_COL                    -1: 0]  r_i_cmd_top_f1              ;
        wire    [NUM_COL*2                  -1: 0]  w_r_i_cmd_top               ;
        reg     [NUM_COL                    -1: 0]  r_i_valid_top               ;
        reg     [NUM_COL*ACCU_DATA_WIDTH    -1: 0]  r_i_data_top                ;
        reg     [NUM_ROW                    -1: 0]  r_i_cmd_left                ;
        reg     [NUM_ROW                    -1: 0]  r_i_valid_left              ;
        reg     [NUM_ROW*DATA_WIDTH         -1: 0]  r_i_data_left               ;
        wire    [NUM_COL*ACCU_DATA_WIDTH    -1: 0]  w_o_data                    ;
        wire    [NUM_ROW                    -1: 0]  w_o_valid                   ;
        // Local Variables //


        systolic_array_datapath#(
                .NUM_ROW            (NUM_ROW                ),
                .NUM_COL            (NUM_COL                ),
                .DATA_WIDTH         (DATA_WIDTH             ),
                .ACCU_DATA_WIDTH    (ACCU_DATA_WIDTH        ),
                .WS_OS              (WS_OS                  )
        )inst_sa_datapath(
                .clk                (clk                    ),
                .rst_n              (rst_n                  ),
                .i_cmd_top          (w_r_i_cmd_top          ),
                .i_valid_top        (r_i_valid_top          ),
                .i_data_top         (r_i_data_top           ),
                .i_cmd_left         (r_i_cmd_left           ),
                .i_valid_left       (r_i_valid_left         ),
                .i_data_left        (r_i_data_left          ),
                .o_data             (w_o_data               ),
                .o_valid            (w_o_valid              )
        );

        inst_reader #(
                .INST_WIDTH             (INST_WIDTH),
                .INST_MEMORY_SIZE       (INST_MEMORY_SIZE),
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

endmodule