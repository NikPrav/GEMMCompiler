`timescale 1ns / 1ps
/*
    Top Module:  systolic_array_datapath
    Data:        SA_IN_DATA_WIDTH is the width of input data -> OUT_WORD_SIZE is the width of output data.
    Timing:      Sequential Logic
    Reset:       Synchronized Reset [High negedge rst_n]

                                     [1*IWS+:IWS]   [3*IWS+:IWS]   
                      weights[0*IWS+:IWS] |[2*IWS+:IWS] |
                                   |      |      |      |
                                   v      v      v      v
          iActs[0*IWS+:IWS]   -->|¯¯¯|--|¯¯¯|--|¯¯¯|--|¯¯¯|--> (left open end)
                                 |___|  |___|  |___|  |___|
                                   |      |      |      |
          iActs[1*IWS+:IWS]   -->|¯¯¯|--|¯¯¯|--|¯¯¯|--|¯¯¯|--> (left open end)
                                 |___|  |___|  |___|  |___|
                                   |      |      |      |
             ...              -->|¯¯¯|--|¯¯¯|--|¯¯¯|--|¯¯¯|--> (left open end)
                                 |___|  |___|  |___|  |___|
                                   |      |      |      |  
       iActs[NUM_ROW*IWS+:IWS]-->|¯¯¯|--|¯¯¯|--|¯¯¯|--|¯¯¯|--> (left open end)
                                 |___|  |___|  |___|  |___|
                                   |      |      |      |
                                   v      v      v      v
                                o_data o_data o_data o_data
                          [0*IWS+:IWS]               [NUM_ROW*IWS+:IWS]

            Every node has an output value;

    Author:      Jianming Tong (jianming.tong@gatech.edu) Anirudh Itagi (aitagi7@gatech.edu)
*/

module systolic_array_datapath#(
    parameter   NUM_ROW             = 8,
    parameter   NUM_COL             = 8,
    parameter   SA_IN_DATA_WIDTH    = 8,
    parameter   SA_OUT_DATA_WIDTH   = 32,
    parameter   WS_OS               = 1     // 0-> WS, 1-> OS, defined at line 57~58.
)(
    clk                 ,
    rst_n               ,
    i_cmd_top           ,
    i_valid_top         ,
    i_data_top          ,
    i_cmd_left          ,
    i_valid_left        ,
    i_data_left         ,
    o_data              ,   // Data from Last Row Down
    o_valid                 // Valid from Last Row Down
);

    /*
        localparam
    */
    localparam TOP_CMD_WIDTH_PER_PE  = 2;   // 
    localparam OS_DATAFLOW = 1;   // 
    localparam WS_DATAFLOW = 0;   // 

    localparam SKEW_LEFT_INPUT_EN = 1;
    localparam SKEW_TOP_INPUT_EN = 1;

    /*
        ports
    */
    input                                                   clk;
    input                                                   rst_n;

    input  [NUM_COL*TOP_CMD_WIDTH_PER_PE-1: 0]              i_cmd_top; 
    input  [NUM_COL                     -1: 0]              i_valid_top;
    input  [NUM_COL*SA_OUT_DATA_WIDTH   -1: 0]              i_data_top;
    input  [NUM_ROW                     -1: 0]              i_cmd_left;
    input  [NUM_ROW                     -1: 0]              i_valid_left;
    input  [NUM_ROW*SA_IN_DATA_WIDTH    -1: 0]              i_data_left;
 
    output [NUM_COL*SA_OUT_DATA_WIDTH   -1: 0]              o_data;
    output [NUM_COL                     -1: 0]              o_valid;
    /*
        inner logics
    */

    genvar gr,gc;
    genvar i,j;
    integer i_r;

    wire                                w_o_valid_top_down      [0 : NUM_ROW  ][0 : NUM_COL-1];
    wire    [SA_OUT_DATA_WIDTH  -1: 0]  w_o_data_top_down       [0 : NUM_ROW  ][0 : NUM_COL-1];
    wire    [TOP_CMD_WIDTH_PER_PE-1:0]  w_o_cmd_top_down        [0 : NUM_ROW  ][0 : NUM_COL-1];
    wire                                w_o_valid_left_right    [0 : NUM_ROW-1][0 : NUM_COL  ];
    wire    [SA_IN_DATA_WIDTH   -1: 0]  w_o_data_left_right     [0 : NUM_ROW-1][0 : NUM_COL  ];
    wire                                w_o_cmd_left_right      [0 : NUM_ROW-1][0 : NUM_COL  ];

    /*
    INPUT FROM TOP
    */
    if (SKEW_TOP_INPUT_EN == 1)
    begin
        // Initialise shift register 
        reg r_top_valid [0: NUM_COL-1];

        // Make always blcok for shifting (sync to clk)
        always@(posedge clk or negedge rst_n)
        begin
            if (!rst_n)
            begin
                for(i_r = 0; i_r<NUM_COL; i_r = i_r+1)
                begin
                    r_top_valid  [i_r] <= 0;
                end
            end
            else
            begin
                r_top_valid [0] <= i_valid_top;
                
                for(i_r = 0; i_r<NUM_COL-1; i_r = i_r+1)
                begin
                    r_top_valid  [i_r+1] <= r_top_valid [i_r];
                end
            end
        end

        
        for(gc=0; gc<NUM_COL; gc=gc+1)
        begin:assign_top_input

            assign w_o_cmd_top_down     [0][gc] = i_cmd_top         [ gc*TOP_CMD_WIDTH_PER_PE +:  TOP_CMD_WIDTH_PER_PE];
            assign w_o_valid_top_down   [0][gc] = r_top_valid       [gc];
            assign w_o_data_top_down    [0][gc] = i_data_top        [(gc*SA_OUT_DATA_WIDTH)   +: SA_OUT_DATA_WIDTH];
        end
    end else begin 
        for(gc=0; gc<NUM_COL; gc=gc+1)
        begin:assign_top_input
            assign w_o_cmd_top_down     [0][gc] = i_cmd_top         [ gc*TOP_CMD_WIDTH_PER_PE +:  TOP_CMD_WIDTH_PER_PE];
            assign w_o_valid_top_down   [0][gc] = i_valid_top       [ gc                      +:  1];
            assign w_o_data_top_down    [0][gc] = i_data_top        [(gc*SA_OUT_DATA_WIDTH)   +: SA_OUT_DATA_WIDTH];
        end
    end


    /*
    INPUT FROM LEFT
    */
    
    if (SKEW_LEFT_INPUT_EN == 1)
    begin
        // Initialise shift register 
        reg r_left_valid [0: NUM_ROW-1];

        // Make always blcok for shifting (sync to clk)
        always@(posedge clk or negedge rst_n)
        begin
            if (!rst_n)
            begin
                for(i_r = 0; i_r<NUM_ROW; i_r = i_r+1)
                begin
                    r_left_valid  [i_r] <= 0;
                end
            end
            else
            begin
                r_left_valid [0] <= i_valid_left;
                
                for(i_r = 0; i_r<NUM_ROW-1; i_r = i_r+1)
                begin
                    r_left_valid  [i_r+1] <= r_left_valid [i_r];
                end
            end
        end

        for(gr=0; gr<NUM_ROW; gr=gr+1)
        begin:assign_left_input
            assign w_o_cmd_left_right   [gr][0] = i_cmd_left        [ gr                    +:  1];
            assign w_o_valid_left_right [gr][0] = r_left_valid      [ gr ];
            assign w_o_data_left_right  [gr][0] = i_data_left       [(gr*SA_IN_DATA_WIDTH)  +: SA_IN_DATA_WIDTH];
        end
    end else begin 
        for(gr=0; gr<NUM_ROW; gr=gr+1)
        begin:assign_left_input
            assign w_o_cmd_left_right   [gr][0] = i_cmd_left        [ gr                    +:  1];
            assign w_o_valid_left_right [gr][0] = i_valid_left      [ gr                    +:  1];
            assign w_o_data_left_right  [gr][0] = i_data_left       [(gr*SA_IN_DATA_WIDTH)  +: SA_IN_DATA_WIDTH];
        end
    end


    /*
        instaniate 2D PE array
    */
    generate
        for(gr=0;gr<NUM_ROW;gr=gr+1)
        begin: pe_row
            for(gc=0;gc<NUM_COL;gc=gc+1)
            begin: pe_col

                if(WS_OS==WS_DATAFLOW)
                    systolic_array_pe_ws#(
                        .SA_IN_DATA_WIDTH   (SA_IN_DATA_WIDTH                       ),
                        .SA_OUT_DATA_WIDTH  (SA_OUT_DATA_WIDTH                      ),
                        .IS_LAST_ROW_PE     (!(NUM_ROW-1-gr)                        )
                    )m_pe(
                        .clk                (clk                                    ),
                        .rst_n              (rst_n                                  ),
                        .i_valid_top        (w_o_valid_top_down     [gr  ][gc  ]    ),
                        .i_cmd_top          (w_o_cmd_top_down       [gr  ][gc  ]    ),
                        .i_data_top         (w_o_data_top_down      [gr  ][gc  ]    ),
                        .o_data_down        (w_o_data_top_down      [gr+1][gc  ]    ),
                        .o_valid_down       (w_o_valid_top_down     [gr+1][gc  ]    ),
                        .o_cmd_down         (w_o_cmd_top_down       [gr+1][gc  ]    ),
                        .i_cmd_left         (w_o_cmd_left_right     [gr  ][gc  ]    ),
                        .i_valid_left       (w_o_valid_left_right   [gr  ][gc  ]    ),
                        .i_data_left        (w_o_data_left_right    [gr  ][gc  ]    ),
                        .o_data_right       (w_o_data_left_right    [gr  ][gc+1]    ),
                        .o_valid_right      (w_o_valid_left_right   [gr  ][gc+1]    ),
                        .o_cmd_right        (w_o_cmd_left_right     [gr  ][gc+1]    )
                    );
                else if(WS_OS==OS_DATAFLOW)
                    systolic_array_pe_os#(
                        .SA_IN_DATA_WIDTH   (SA_IN_DATA_WIDTH                       ),
                        .SA_OUT_DATA_WIDTH  (SA_OUT_DATA_WIDTH                      ),
                        .ROW_ID             (gr                                     ),
                        .LAST_ROW_ID        (NUM_ROW-1                              )
                    )m_pe(
                        .clk                (clk                                    ),
                        .rst_n              (rst_n                                  ),
                        .i_valid_top        (w_o_valid_top_down     [gr  ][gc  ]    ),
                        .i_cmd_top          (w_o_cmd_top_down       [gr  ][gc  ]    ),
                        .i_data_top         (w_o_data_top_down      [gr  ][gc  ]    ),
                        .o_data_down        (w_o_data_top_down      [gr+1][gc  ]    ),
                        .o_valid_down       (w_o_valid_top_down     [gr+1][gc  ]    ),
                        .o_cmd_down         (w_o_cmd_top_down       [gr+1][gc  ]    ),
                        .i_cmd_left         (w_o_cmd_left_right     [gr  ][gc  ]    ),
                        .i_valid_left       (w_o_valid_left_right   [gr  ][gc  ]    ),
                        .i_data_left        (w_o_data_left_right    [gr  ][gc  ]    ),
                        .o_data_right       (w_o_data_left_right    [gr  ][gc+1]    ),
                        .o_valid_right      (w_o_valid_left_right   [gr  ][gc+1]    ),
                        .o_cmd_right        (w_o_cmd_left_right     [gr  ][gc+1]    )
                    );
            end
        end
    endgenerate

    /*
        Output From Bottom
    */
    generate
        for(gc=0; gc<NUM_COL; gc=gc+1)
        begin:output_assign
            assign o_data   [(gc*SA_OUT_DATA_WIDTH) +:  SA_OUT_DATA_WIDTH]  = w_o_data_top_down [NUM_ROW][gc];
            assign o_valid  [gc]                                            = w_o_valid_top_down[NUM_ROW][gc];
        end
    endgenerate

endmodule