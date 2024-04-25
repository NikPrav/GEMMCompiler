`timescale 1ns/1ps

/*
    Top Module:  tb_systolic_array_datapath
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

    Author:      Jianming Tong (jianming.tong@gatech.edu) Anirudh Itagi (aitagi7@gatech.edu)
*/

`define PERIOD 10


module tb_systolic_array_datapath();
    parameter                                   NUM_ROW             =   4   ;
    parameter                                   NUM_COL             =   4   ;
    parameter                                   DATA_WIDTH          =   8   ;
    parameter                                   ACCU_DATA_WIDTH     =   32  ;
    parameter                                   WS_OS               =   1   ;   // O-> ws, 1-> os

    reg                                         clk                 =   0   ;
    reg                                         rst_n               =   0   ;
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

    // Inst_reader variables //
    parameter INST_WIDTH            = 16;
    parameter INST_MEMORY_SIZE      = 1024;

    parameter OPCODE_WIDTH  = 4;
    parameter BUF_ID_WIDTH  = 2;
    parameter MEM_LOC_WIDTH = 10;

    parameter MEM_LOC_ARRAY_INDEX   = MEM_LOC_WIDTH;
    parameter BUF_ID_ARRAY_INDEX    = MEM_LOC_ARRAY_INDEX + BUF_ID_WIDTH;
    parameter OPCODE_ARRAY_INDEX    = BUF_ID_ARRAY_INDEX + OPCODE_WIDTH;

    parameter opcode_LD             = 4'b0010;
    parameter opcode_ST             = 4'b0011;
    parameter opcode_GEMM           = 4'b0100;
    parameter opcode_DRAINSYS       = 4'b0101;

    reg [OPCODE_WIDTH - 1: 0]   opcode;
    reg [BUF_ID_WIDTH - 1: 0]   buf_id;
    reg [MEM_LOC_WIDTH - 1: 0]  mem_loc;
    // Inst_reader variables //

    // Changed the following
    initial 
    begin
        rst_n           = 0;
        r_i_data_top    = 0;
        r_i_cmd_top     = 0;
        r_i_valid_top   = 0;
        r_i_data_left   = 0;
        r_i_cmd_left    = 0;
        r_i_valid_left  = 0;
        r_i_cmd_top_f1  = 0;
        #(`PERIOD)
        rst_n = 1;

        if(WS_OS == 0)
        begin
            @(posedge clk);
            r_i_data_top = 128'h00000014_00000013_00000012_00000011;
            r_i_cmd_top = 4'b1_1_1_1;
            r_i_valid_top = 4'b1_1_1_1;
            r_i_data_left = 32'h00_00_00_00;
            r_i_cmd_left = 4'b0_0_0_0;
            r_i_valid_left = 4'b0_0_0_0;
            @(posedge clk);
            r_i_data_top = 128'h00000018_00000017_00000016_00000015;
            r_i_cmd_top = 4'b1_1_1_1;
            r_i_valid_top = 4'b1_1_1_1;
            r_i_data_left = 32'h00_00_00_00;
            r_i_cmd_left = 4'b0_0_0_0;
            r_i_valid_left = 4'b0_0_0_0;
            @(posedge clk);
            r_i_data_top = 128'h0000001c_0000001b_0000001a_00000019;
            r_i_cmd_top = 4'b1_1_1_1;
            r_i_valid_top = 4'b1_1_1_1;
            r_i_data_left = 32'h00_00_00_00;
            r_i_cmd_left = 4'b0_0_0_0;
            r_i_valid_left = 4'b0_0_0_0;
            @(posedge clk);
            r_i_data_top = 128'h00000020_0000001f_0000001e_0000001d;
            r_i_cmd_top = 4'b1_1_1_1;
            r_i_valid_top = 4'b1_1_1_1;
            r_i_data_left = 32'h00_00_00_00;
            r_i_cmd_left = 4'b0_0_0_0;
            r_i_valid_left = 4'b0_0_0_0;
            @(posedge clk);
            r_i_data_top = 128'h00000000_00000000_00000000_00000000;
            r_i_cmd_top = 4'b0_0_0_0;
            r_i_valid_top = 4'b0_0_0_0;
            r_i_data_left = 32'h00_00_00_01;
            r_i_cmd_left = 4'b0_0_0_1;
            r_i_valid_left = 4'b0_0_0_1;
            @(posedge clk);
            r_i_data_top = 128'h00000000_00000000_00000000_00000000;
            r_i_cmd_top = 4'b0_0_0_0;
            r_i_valid_top = 4'b0_0_0_0;
            r_i_data_left = 32'h00_00_02_05;
            r_i_cmd_left = 4'b0_0_1_1;
            r_i_valid_left = 4'b0_0_1_1;
            @(posedge clk);
            r_i_data_top = 128'h00000000_00000000_00000000_00000000;
            r_i_cmd_top = 4'b0_0_0_0;
            r_i_valid_top = 4'b0_0_0_0;
            r_i_data_left = 32'h00_03_06_09;
            r_i_cmd_left = 4'b0_1_1_1;
            r_i_valid_left = 4'b0_1_1_1;
            @(posedge clk);
            r_i_data_top = 128'h00000000_00000000_00000000_00000000;
            r_i_cmd_top = 4'b0_0_0_0;
            r_i_valid_top = 4'b0_0_0_0;
            r_i_data_left = 32'h04_07_0a_0d;
            r_i_cmd_left = 4'b1_1_1_1;
            r_i_valid_left = 4'b1_1_1_1;
            @(posedge clk);
            r_i_data_top = 128'h00000000_00000000_00000000_00000000;
            r_i_cmd_top = 4'b0_0_0_0;
            r_i_valid_top = 4'b0_0_0_0;
            r_i_data_left = 32'h08_0b_0e_00;
            r_i_cmd_left = 4'b1_1_1_0;
            r_i_valid_left = 4'b1_1_1_0;
            @(posedge clk);
            r_i_data_top = 128'h00000000_00000000_00000000_00000000;
            r_i_cmd_top = 4'b0_0_0_0;
            r_i_valid_top = 4'b0_0_0_0;
            r_i_data_left = 32'h0c_0f_00_00;
            r_i_cmd_left = 4'b1_1_0_0;
            r_i_valid_left = 4'b1_1_0_0;
            @(posedge clk);
            r_i_data_top = 128'h00000000_00000000_00000000_00000000;
            r_i_cmd_top = 4'b0_0_0_0;
            r_i_valid_top = 4'b0_0_0_0;
            r_i_data_left = 32'h10_00_00_00;
            r_i_cmd_left = 4'b1_0_0_0;
            r_i_valid_left = 4'b1_0_0_0;
            @(posedge clk);
            r_i_data_top = 128'h00000000_00000000_00000000_00000000;
            r_i_cmd_top = 4'b0_0_0_0;
            r_i_valid_top = 4'b0_0_0_0;
            r_i_data_left = 32'h00_00_00_00;
            r_i_cmd_left = 4'b0_0_0_0;
            r_i_valid_left = 4'b0_0_0_0;
            @(posedge clk);
            r_i_data_top = 128'h00000000_00000000_00000000_00000000;
            r_i_cmd_top = 4'b0_0_0_0;
            r_i_valid_top = 4'b0_0_0_0;
            r_i_data_left = 32'h00_00_00_00;
            r_i_cmd_left = 4'b0_0_0_0;
            r_i_valid_left = 4'b0_0_0_0;
            @(posedge clk);
            r_i_data_top = 128'h00000000_00000000_00000000_00000000;
            r_i_cmd_top = 4'b0_0_0_0;
            r_i_valid_top = 4'b0_0_0_0;
            r_i_data_left = 32'h00_00_00_00;
            r_i_cmd_left = 4'b0_0_0_0;
            r_i_valid_left = 4'b0_0_0_0;
            @(posedge clk);
            r_i_data_top = 128'h00000000_00000000_00000000_00000000;
            r_i_cmd_top = 4'b0_0_0_0;
            r_i_valid_top = 4'b0_0_0_0;
            r_i_data_left = 32'h00_00_00_00;
            r_i_cmd_left = 4'b0_0_0_0;
            r_i_valid_left = 4'b0_0_0_0;

            @(posedge clk);
            //flush begin
            r_i_cmd_top = 4'b0_0_0_0;
            r_i_cmd_top_f1 = 4'b1_1_1_1;

            @(posedge clk);
            //warmup begin
            r_i_cmd_top_f1 = 4'b0_0_0_0;
            r_i_data_top = 128'h00000014_00000013_00000012_00000011;
            r_i_cmd_top = 4'b1_1_1_1;
            r_i_valid_top = 4'b1_1_1_1;
            r_i_data_left = 32'h00_00_00_00;
            r_i_cmd_left = 4'b0_0_0_0;
            r_i_valid_left = 4'b0_0_0_0;
            @(posedge clk);
            r_i_data_top = 128'h00000018_00000017_00000016_00000015;
            r_i_cmd_top = 4'b1_1_1_1;
            r_i_valid_top = 4'b1_1_1_1;
            r_i_data_left = 32'h00_00_00_00;
            r_i_cmd_left = 4'b0_0_0_0;
            r_i_valid_left = 4'b0_0_0_0;
            @(posedge clk);
            r_i_data_top = 128'h0000001c_0000001b_0000001a_00000019;
            r_i_cmd_top = 4'b1_1_1_1;
            r_i_valid_top = 4'b1_1_1_1;
            r_i_data_left = 32'h00_00_00_00;
            r_i_cmd_left = 4'b0_0_0_0;
            r_i_valid_left = 4'b0_0_0_0;
            @(posedge clk);
            r_i_data_top = 128'h00000020_0000001f_0000001e_0000001d;
            r_i_cmd_top = 4'b1_1_1_1;
            r_i_valid_top = 4'b1_1_1_1;
            r_i_data_left = 32'h00_00_00_00;
            r_i_cmd_left = 4'b0_0_0_0;
            r_i_valid_left = 4'b0_0_0_0;
            @(posedge clk);

        end
        else if(WS_OS==1)
        begin

            /*
                wm = np.array([ [  1,  5, 10, 15],
                                [  1, 20, 25, 30],
                                [  1, 35, 40, 45],
                                [  1, 50, 55, 60]])

                am = np.array([ [  1,  5,  9, 13],
                                [  2,  6, 10, 14],
                                [  3,  7, 11, 15],
                                [  4,  8, 12, 16]])

                wmam = np.matmul(wm, am) = 
                [
                    [ 101  225  349  473]
                    [ 236  540  844 1148]
                    [ 371  855 1339 1823]
                    [ 506 1170 1834 2498]
                ]
            */


            r_i_cmd_top_f1  =   {  1'b0,  1'b0,  1'b0,  1'b0};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_valid_top   =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_data_top    =   {     0,     0,     0,     0};
            r_i_cmd_left    =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_valid_left  =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_data_left   =   {  8'd0,  8'd0,  8'd0,  8'd0};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b0,  1'b0,  1'b0,  1'b1};
            r_i_valid_top   =   {  1'b0,  1'b0,  1'b0,  1'b1};
            r_i_data_top    =   {     0,     0,     0,     1};
            r_i_cmd_left    =   {  1'b0,  1'b0,  1'b0,  1'b1};
            r_i_valid_left  =   {  1'b0,  1'b0,  1'b0,  1'b1};
            r_i_data_left   =   {  8'd0,  8'd0,  8'd0,  8'd1};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b0,  1'b0,  1'b1,  1'b1};
            r_i_valid_top   =   {  1'b0,  1'b0,  1'b1,  1'b1};
            r_i_data_top    =   {     0,     0,     1,     5};
            r_i_cmd_left    =   {  1'b0,  1'b0,  1'b1,  1'b1};
            r_i_valid_left  =   {  1'b0,  1'b0,  1'b1,  1'b1};
            r_i_data_left   =   {  8'd0,  8'd0,  8'd5,  8'd2};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b0,  1'b1,  1'b1,  1'b1};
            r_i_valid_top   =   {  1'b0,  1'b1,  1'b1,  1'b1};
            r_i_data_top    =   {     0,     1,    20,    10};
            r_i_cmd_left    =   {  1'b0,  1'b1,  1'b1,  1'b1};
            r_i_valid_left  =   {  1'b0,  1'b1,  1'b1,  1'b1};
            r_i_data_left   =   {  8'd0,  8'd9,  8'd6,  8'd3};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b1,  1'b1,  1'b1,  1'b1};
            r_i_valid_top   =   {  1'b1,  1'b1,  1'b1,  1'b1};
            r_i_data_top    =   {     1,    35,    25,    15};
            r_i_cmd_left    =   {  1'b1,  1'b1,  1'b1,  1'b1};
            r_i_valid_left  =   {  1'b1,  1'b1,  1'b1,  1'b1};
            r_i_data_left   =   { 8'd13, 8'd10,  8'd7,  8'd4};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b1,  1'b1,  1'b1,  1'b0};
            r_i_valid_top   =   {  1'b1,  1'b1,  1'b1,  1'b0};
            r_i_data_top    =   {    50,    40,    30,     0};
            r_i_cmd_left    =   {  1'b1,  1'b1,  1'b1,  1'b1};
            r_i_valid_left  =   {  1'b1,  1'b1,  1'b1,  1'b1};
            r_i_data_left   =   { 8'd14, 8'd11,  8'd8,  8'd0};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b1,  1'b1,  1'b0,  1'b0};
            r_i_valid_top   =   {  1'b1,  1'b1,  1'b0,  1'b0};
            r_i_data_top    =   {    55,    45,     0,     0};
            r_i_cmd_left    =   {  1'b1,  1'b1,  1'b0,  1'b0};
            r_i_valid_left  =   {  1'b1,  1'b1,  1'b0,  1'b0};
            r_i_data_left   =   { 8'd15, 8'd12,  8'd0,  8'd0};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b1,  1'b0,  1'b0,  1'b0};
            r_i_valid_top   =   {  1'b1,  1'b0,  1'b0,  1'b0};
            r_i_data_top    =   {    60,     0,     0,     0};
            r_i_cmd_left    =   {  1'b1,  1'b0,  1'b0,  1'b0};
            r_i_valid_left  =   {  1'b1,  1'b0,  1'b0,  1'b0};
            r_i_data_left   =   { 8'd16,  8'd0,  8'd0,  8'd0};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_valid_top   =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_data_top    =   {     0,     0,     0,     0};
            r_i_cmd_left    =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_valid_left  =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_data_left   =   {  8'd0,  8'd0,  8'd0,  8'd0};


            @(posedge clk);
            r_i_cmd_top_f1  =   {  1'b1,  1'b1,  1'b1,  1'b1};
            r_i_cmd_top     =   {  1'b1,  1'b1,  1'b1,  1'b1};
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            r_i_cmd_top_f1  =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_cmd_top     =   {  1'b0,  1'b0,  1'b0,  1'b0};


            /*
                [
                [1,  5,  10,  15]       [1, 5]
                [1, 35,  40,  45]       [2, 6]
                [1, 20,  25,  30]   *   [3, 7]
                [1, 50,  55,  60]       [4, 8]
                                ]


                wm = np.array([ [1,  5, 10, 15],
                                [1, 20, 25, 30],
                                [1, 35, 40, 45],
                                [1, 50, 55, 60]])
                am = np.array([ [1, 5],
                                [2, 6],
                                [3, 7],
                                [4, 8]])

                wmam = np.matmul(wm, am) = 
                OUTPUT=         [
                                    [ 101 , 225]
                                    [ 236 , 540]
                                    [ 371 , 855]
                                    [ 506 ,1170]]

            */
            r_i_cmd_top_f1  =   {  1'b0,  1'b0,  1'b0,  1'b0};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_valid_top   =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_data_top    =   {     0,     0,     0,     0};
            r_i_cmd_left    =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_valid_left  =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_data_left   =   {  8'd0,  8'd0,  8'd0,  8'd0};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b0,  1'b0,  1'b0,  1'b1};
            r_i_valid_top   =   {  1'b0,  1'b0,  1'b0,  1'b1};
            r_i_data_top    =   {     0,     0,     0,     1};
            r_i_cmd_left    =   {  1'b0,  1'b0,  1'b0,  1'b1};
            r_i_valid_left  =   {  1'b0,  1'b0,  1'b0,  1'b1};
            r_i_data_left   =   {  8'd0,  8'd0,  8'd0,  8'd1};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b0,  1'b0,  1'b1,  1'b1};
            r_i_valid_top   =   {  1'b0,  1'b0,  1'b1,  1'b1};
            r_i_data_top    =   {     0,     0,     1,     5};
            r_i_cmd_left    =   {  1'b0,  1'b0,  1'b1,  1'b1};
            r_i_valid_left  =   {  1'b0,  1'b0,  1'b1,  1'b1};
            r_i_data_left   =   {  8'd0,  8'd0,  8'd5,  8'd2};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b0,  1'b1,  1'b1,  1'b1};
            r_i_valid_top   =   {  1'b0,  1'b1,  1'b1,  1'b1};
            r_i_data_top    =   {     0,     1,    20,    10};
            r_i_cmd_left    =   {  1'b0,  1'b0,  1'b1,  1'b1};
            r_i_valid_left  =   {  1'b0,  1'b0,  1'b1,  1'b1};
            r_i_data_left   =   {  8'd0,  8'd0,  8'd6,  8'd3};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b1,  1'b1,  1'b1,  1'b1};
            r_i_valid_top   =   {  1'b1,  1'b1,  1'b1,  1'b1};
            r_i_data_top    =   {     1,    35,    25,    15};
            r_i_cmd_left    =   {  1'b0,  1'b0,  1'b1,  1'b1};
            r_i_valid_left  =   {  1'b0,  1'b0,  1'b1,  1'b1};
            r_i_data_left   =   {  8'd0,  8'd0,  8'd7,  8'd4};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b1,  1'b1,  1'b1,  1'b0};
            r_i_valid_top   =   {  1'b1,  1'b1,  1'b1,  1'b0};
            r_i_data_top    =   {    50,    40,    30,     0};
            r_i_cmd_left    =   {  1'b0,  1'b0,  1'b1,  1'b1};
            r_i_valid_left  =   {  1'b0,  1'b0,  1'b1,  1'b1};
            r_i_data_left   =   {  8'd0,  8'd0,  8'd8,  8'd0};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b1,  1'b1,  1'b0,  1'b0};
            r_i_valid_top   =   {  1'b1,  1'b1,  1'b0,  1'b0};
            r_i_data_top    =   {    55,    45,     0,     0};
            r_i_cmd_left    =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_valid_left  =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_data_left   =   {  8'd0,  8'd0,  8'd0,  8'd0};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b1,  1'b0,  1'b0,  1'b0};
            r_i_valid_top   =   {  1'b1,  1'b0,  1'b0,  1'b0};
            r_i_data_top    =   {    60,     0,     0,     0};
            r_i_cmd_left    =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_valid_left  =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_data_left   =   {  8'd0,  8'd0,  8'd0,  8'd0};

            @(posedge clk);
            r_i_cmd_top     =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_valid_top   =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_data_top    =   {     0,     0,     0,     0};
            r_i_cmd_left    =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_valid_left  =   {  1'b0,  1'b0,  1'b0,  1'b0};
            r_i_data_left   =   {  8'd0,  8'd0,  8'd0,  8'd0};


            @(posedge clk);
            r_i_cmd_top_f1  =   {  1'b1,  1'b1,  1'b1,  1'b1};
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            r_i_cmd_top_f1  =   {  1'b0,  1'b0,  1'b0,  1'b0};

        end
//        $stop;
    end

    genvar gv;
    generate
        for(gv=0; gv < NUM_COL; gv=gv+1)
        begin
            assign w_r_i_cmd_top[gv*2 +: 2] = {r_i_cmd_top_f1[gv],r_i_cmd_top[gv]};
        end
    endgenerate

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

    // Free running clk
    always #(`PERIOD/2) clk = ~clk;
endmodule