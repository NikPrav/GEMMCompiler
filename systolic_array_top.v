`timescale 1ns / 1ps
/*
 Top Module:  systolic_array_datapath
 Data:        DATA_WIDTH is the width of input data -> OUT_WORD_SIZE is the width of output data.
 Format:      OUT_WORD_SIZE = DATA_WIDTH << 1; beacuse multiplication happen inside
 Timing:      Sequential Logic
 Reset:       Synchronized Reset [High negedge rst_n]
 Dummy Data:  {DATA_WIDTH{1'b0}}
 
 Function:   Output Stationary.
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

module systolic_array_top#(parameter NUM_ROW = 8,
                           parameter NUM_COL = 8,
                           parameter DATA_WIDTH = 8,
                           parameter ACCU_DATA_WIDTH = 32,
                           parameter LOG2_SRAM_BANK_DEPTH = 10,
                           parameter SKEW_TOP_INPUT_EN = 1,
                           parameter SKEW_LEFT_INPUT_EN = 1)
                          (clk,
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
                           i_down_sram_rd_end_addr);
    
    /*
     localparam
     */
    localparam  OUT_DATA_WIDTH = ACCU_DATA_WIDTH;
    localparam  CTRL_WIDTH     = 4;
    
    /*
     ports
     */
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
    
    wire    [DATA_WIDTH             : 0]                      w_i_top_wr_data     [0 : NUM_COL-1] ; // Changed to DATAWIDTH+1
    wire    [DATA_WIDTH             : 0]                      w_o_top_rd_data     [0 : NUM_COL-1] ; // Changed to DATAWIDTH+1
    wire    [DATA_WIDTH             : 0]                      w_i_left_wr_data    [0 : NUM_ROW-1] ; // Changed to DATAWIDTH+1
    wire    [DATA_WIDTH             : 0]                      w_o_left_rd_data    [0 : NUM_ROW-1] ; // Changed to DATAWIDTH+1
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
    /*
     inner logics
     ToDo: Wrap all underlying modules into this top module.
     */

    // Added flush wire
    wire w_cmd_top_flsh;

    assign w_cmd_top_flsh = (i_ctrl_state == 3) ? 1: 0;
    
    integer  i_r, i_c;
    genvar   gr, gc;
    
    generate
    //---------------------------------------------------------------------------------------------------
    if (SKEW_TOP_INPUT_EN == 1)
    begin
        reg                                                 r_top_rd_wr_en [0 : NUM_ROW-1];
        reg [LOG2_SRAM_BANK_DEPTH       -1: 0]              r_top_addr     [0 : NUM_ROW-1];
        /*
         Skew the rd addr and rd enable for the left input
         */
        always@(posedge clk or negedge rst_n)
        begin
            if (!rst_n)
            begin
                for(i_r = 0; i_r<NUM_ROW; i_r = i_r+1)
                begin
                    r_top_rd_wr_en  [i_r] <= 0;
                    r_top_addr      [i_r] <= 0;
                end
            end
            else
            begin
                r_top_rd_wr_en [0] <= w_top_rd_wr_en_from_ctrl;
                r_top_addr     [0] <= w_top_rd_wr_addr_from_ctrl;
                for(i_r = 0; i_r<NUM_ROW-1; i_r = i_r+1)
                begin
                    r_top_rd_wr_en  [i_r+1] <= r_top_rd_wr_en [i_r];
                    r_top_addr      [i_r+1] <= r_top_addr     [i_r];
                end
            end
        end
        
        for(gc = 0; gc<NUM_COL; gc = gc+1)
            begin : sram
            assign  w_i_top_wr_data [gc] = {1, i_top_wr_data[gc*DATA_WIDTH +:  DATA_WIDTH]};
            sram_bank_sp#(
            .SRAM_BANK_DATA_WIDTH   (DATA_WIDTH+1),  // +1 for the CMD
            .SRAM_BANK_ADDR_WIDTH   (LOG2_SRAM_BANK_DEPTH),
            .SRAM_BANK_DEPTH        (1<<LOG2_SRAM_BANK_DEPTH)
            ) sram_bank_sp_top_inst(
            .clk                    (clk),
            .rst_n                  (rst_n),
            .i_rd_wr_en             (r_top_rd_wr_en         [gc]),
            .i_addr                 (r_top_addr             [gc]),
            .i_wr_data              (w_i_top_wr_data        [gc]),
            .o_rd_data              (w_o_top_rd_data        [gc])
            );
    end
    
    end
    else
    begin
    reg                                                 r_top_rd_wr_en;
    reg [LOG2_SRAM_BANK_DEPTH       -1: 0]              r_top_addr    ;
    always@(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            r_top_rd_wr_en <= 0;
            r_top_addr     <= 0;
        end
        else
        begin
            r_top_rd_wr_en <= w_top_rd_wr_en_from_ctrl;
            r_top_addr     <= w_top_rd_wr_addr_from_ctrl;
        end
    end
    
    for(gc = 0; gc<NUM_COL; gc = gc+1)
        begin : sram_bank_top
        assign  w_i_top_wr_data [gc] = {1, i_top_wr_data[gc*DATA_WIDTH +:  DATA_WIDTH]};
        sram_bank_sp#(
        .SRAM_BANK_DATA_WIDTH   (DATA_WIDTH+1),  // +1 for the CMD
        .SRAM_BANK_ADDR_WIDTH   (LOG2_SRAM_BANK_DEPTH),
        .SRAM_BANK_DEPTH        (1<<LOG2_SRAM_BANK_DEPTH)
        ) sram_bank_sp_top_inst(
        .clk                    (clk),
        .rst_n                  (rst_n),
        .i_rd_wr_en             (r_top_rd_wr_en),
        .i_addr                 (r_top_addr),
        .i_wr_data              (w_i_top_wr_data    [gc]),
        .o_rd_data              (w_o_top_rd_data    [gc])
        );
    end
    end
    //---------------------------------------------------------------------------------------------------
    
    
    //---------------------------------------------------------------------------------------------------
    if (SKEW_LEFT_INPUT_EN == 1)
    begin
        // do we need to do for data as well??
        reg                                                 r_left_rd_wr_en [0 : NUM_ROW-1];
        reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]          r_left_addr     [0 : NUM_ROW-1];
        /*
         Skew the rd addr and rd enable for the left input
         */
        always@(posedge clk or negedge rst_n)
        begin
            if (!rst_n)
            begin
                for(i_r = 0; i_r<NUM_ROW; i_r = i_r+1)
                begin
                    r_left_rd_wr_en  [i_r] <= 0;
                    r_left_addr      [i_r] <= 0;
                end
            end
            else
            begin
                r_left_rd_wr_en [0] <= w_left_rd_wr_en_from_ctrl;
                r_left_addr     [0] <= w_left_rd_wr_addr_from_ctrl;
                for(i_r = 0; i_r<NUM_ROW-1; i_r = i_r+1)
                begin
                    r_left_rd_wr_en  [i_r+1] <= r_left_rd_wr_en [i_r];
                    r_left_addr      [i_r+1] <= r_left_addr     [i_r];
                end
            end
        end
        
        for(gr = 0; gr<NUM_ROW; gr = gr+1)
            begin : sram_bank_left
            assign  w_i_left_wr_data [gr] = {1, i_left_wr_data[gr*DATA_WIDTH +:  DATA_WIDTH]};
            sram_bank_sp#(
            .SRAM_BANK_DATA_WIDTH   (DATA_WIDTH+1),  // +1 for the CMD
            .SRAM_BANK_ADDR_WIDTH   (LOG2_SRAM_BANK_DEPTH),
            .SRAM_BANK_DEPTH        (1<<LOG2_SRAM_BANK_DEPTH)
            ) sram_bank_sp_left_inst(
            .clk                    (clk),
            .rst_n                  (rst_n),
            .i_rd_wr_en             (r_left_rd_wr_en        [gr]),
            .i_addr                 (r_left_addr            [gr]),
            .i_wr_data              (w_i_left_wr_data       [gr]),
            .o_rd_data              (w_o_left_rd_data       [gr])
            );
    end
    
    end
    else
    begin
    
    reg                                                     r_left_rd_wr_en;
    reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]              r_left_addr    ;
    
    always@(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            r_left_rd_wr_en <= 0;
            r_left_addr     <= 0;
        end
        else
        begin
            r_left_rd_wr_en <= w_left_rd_wr_en_from_ctrl;
            r_left_addr     <= w_left_rd_wr_addr_from_ctrl;
        end
    end
    
    for(gr = 0; gr<NUM_ROW; gr = gr+1)
        begin : sram_bank_sp_left
        assign  w_i_left_wr_data [gr] = {1, i_left_wr_data[gr*DATA_WIDTH +:  DATA_WIDTH]};
        sram_bank_sp#(
        .SRAM_BANK_DATA_WIDTH   (DATA_WIDTH+1),  // +1 for the CMD
        .SRAM_BANK_ADDR_WIDTH   (LOG2_SRAM_BANK_DEPTH),
        .SRAM_BANK_DEPTH        (1<<LOG2_SRAM_BANK_DEPTH)
        ) sram_bank_sp_left_inst(
        .clk                    (clk),
        .rst_n                  (rst_n),
        .i_rd_wr_en             (r_left_rd_wr_en),
        .i_addr                 (r_left_addr),
        .i_wr_data              (w_i_left_wr_data   [gr]),
        .o_rd_data              (w_o_left_rd_data   [gr])
        );
    end
    end
    //---------------------------------------------------------------------------------------------------
    
    
    wire                                w_i_down_rd_wr_en[0 : NUM_COL-1];
    wire    [OUT_DATA_WIDTH     -1: 0]  w_i_down_wr_data [0 : NUM_COL-1];
    wire    [OUT_DATA_WIDTH     -1: 0]  w_o_down_rd_data [0 : NUM_COL-1];
    
    for(gc = 0; gc<NUM_COL; gc = gc+1)
        begin : sram_bank_down
        sram_bank_sp#(
        .SRAM_BANK_DATA_WIDTH       (ACCU_DATA_WIDTH),  // +1 for the CMD
        .SRAM_BANK_ADDR_WIDTH       (LOG2_SRAM_BANK_DEPTH),
        .SRAM_BANK_DEPTH            (1<<LOG2_SRAM_BANK_DEPTH)
        ) sram_bank_sp_down_inst(
        .clk                        (clk),
        .rst_n                      (rst_n),
        .i_rd_wr_en                 (w_i_down_rd_wr_en      [gc]),
        .i_addr                     (w_down_rd_wr_addr_from_ctrl),
        .i_wr_data                  (w_i_down_wr_data       [gc]),
        .o_rd_data                  (w_o_down_rd_data       [gc])
        );
    end
    
    endgenerate
    
    generate
    wire    [NUM_COL*2                  -1: 0]  w_i_cmd_top_to_sa       ; // Added *2
    wire    [NUM_COL                    -1: 0]  w_i_valid_top_to_sa     ;
    wire    [NUM_COL*ACCU_DATA_WIDTH    -1: 0]  w_i_data_top_to_sa      ;
    wire    [NUM_ROW                    -1: 0]  w_i_cmd_left_to_sa      ;
    wire    [NUM_ROW                    -1: 0]  w_i_valid_left_to_sa    ;
    wire    [NUM_ROW*DATA_WIDTH         -1: 0]  w_i_data_left_to_sa     ;
    
    for(gc = 0; gc<NUM_COL; gc = gc+1)
        begin : w_i_gc
        // assign  w_i_cmd_top_to_sa     [0][gc]                                          = w_o_top_rd_data         [gc][DATA_WIDTH];
        // assign  w_i_cmd_top_to_sa [1][gc] = w_cmd_top_flsh; // Added
        assign  w_i_cmd_top_to_sa[gc*2 +: 2] = {w_cmd_top_flsh ,w_o_top_rd_data [gc][DATA_WIDTH]};
        
        assign  w_i_valid_top_to_sa     [gc]                                          = w_top_valid_from_ctrl   [gc];
        assign  w_i_data_top_to_sa      [(gc*ACCU_DATA_WIDTH)    +:  ACCU_DATA_WIDTH] = {0, w_o_top_rd_data     [gc][0  +:  DATA_WIDTH]};
    
    assign  w_i_down_rd_wr_en       [gc] = w_down_rd_wr_en_from_ctrl;
    assign  w_i_down_wr_data        [gc] = w_o_data_down_from_sa   [(gc*OUT_DATA_WIDTH)    +:  OUT_DATA_WIDTH];
    
    // ADDED: Assign rd_out of bottom SRAM to the output port of the top module, might need reordering of indices
    assign o_down_rd_data [gc] = w_o_down_rd_data[gc];
    end
    
    for(gr = 0; gr<NUM_ROW; gr = gr+1)
        begin : w_i_gr
        assign  w_i_cmd_left_to_sa      [gr]                                = w_o_left_rd_data        [gr][DATA_WIDTH];
        assign  w_i_valid_left_to_sa    [gr]                                = w_left_valid_from_ctrl  [gr];
        assign  w_i_data_left_to_sa     [(gr*DATA_WIDTH)    +:  DATA_WIDTH] = w_o_left_rd_data        [gr];
    end
    endgenerate
    
    systolic_array_datapath#(
    .NUM_ROW                            (NUM_ROW),
    .NUM_COL                            (NUM_COL),
    .SA_IN_DATA_WIDTH                   (DATA_WIDTH),  //changed when pe_os was added
    .SA_OUT_DATA_WIDTH                  (ACCU_DATA_WIDTH) //changed when pe_os was added
    ) inst_sa_datapath(
    .clk                                (clk),
    .rst_n                              (rst_n),
    .i_cmd_top                          (w_i_cmd_top_to_sa),
    .i_valid_top                        (w_i_valid_top_to_sa),
    .i_data_top                         (w_i_data_top_to_sa),
    .i_cmd_left                         (w_i_cmd_left_to_sa),
    .i_valid_left                       (w_i_valid_left_to_sa),
    .i_data_left                        (w_i_data_left_to_sa),
    .o_data                             (w_o_data_down_from_sa),
    .o_valid                            (w_o_valid_down_from_sa)
    );
    
    systolic_array_controller#(
    .NUM_ROW                            (NUM_ROW),
    .NUM_COL                            (NUM_COL),
    .DATA_WIDTH                         (DATA_WIDTH),
    .ACCU_DATA_WIDTH                    (ACCU_DATA_WIDTH),
    .LOG2_SRAM_BANK_DEPTH (LOG2_SRAM_BANK_DEPTH)
    ) inst_sa_controller(
    .clk                                (clk),
    .rst_n                              (rst_n),
    .i_ctrl_state_to_ctrl               (i_ctrl_state),
    .i_top_wr_en_to_ctrl                (i_top_wr_en),
    .i_top_wr_addr_to_ctrl              (i_top_wr_addr),
    .i_left_wr_en_to_ctrl               (i_left_wr_en),
    .i_left_wr_addr_to_ctrl             (i_left_wr_addr),
    .i_down_rd_en_to_ctrl               (i_down_rd_en),
    .i_down_rd_addr_to_ctrl             (i_down_rd_addr),
    .o_top_rd_wr_en_from_ctrl           (w_top_rd_wr_en_from_ctrl),
    .o_top_rd_wr_addr_from_ctrl         (w_top_rd_wr_addr_from_ctrl),
    .o_left_rd_wr_en_from_ctrl          (w_left_rd_wr_en_from_ctrl),
    .o_left_rd_wr_addr_from_ctrl        (w_left_rd_wr_addr_from_ctrl),
    
    .o_down_rd_wr_en_from_ctrl          (w_down_rd_wr_en_from_ctrl),
    .o_down_rd_wr_addr_from_ctrl        (w_down_rd_wr_addr_from_ctrl),
    
    .i_top_sram_rd_start_addr (i_top_sram_rd_start_addr),
    .i_top_sram_rd_end_addr (i_top_sram_rd_end_addr),
    
    .i_left_sram_rd_start_addr (i_left_sram_rd_start_addr),
    .i_left_sram_rd_end_addr (i_left_sram_rd_end_addr),
    
    .i_sa_datapath_valid_down_to_ctrl   (w_o_valid_down_from_sa),
    .o_valid_top_from_ctrl              (w_top_valid_from_ctrl),
    .o_valid_left_from_ctrl             (w_left_valid_from_ctrl)
    );
    
    
endmodule
