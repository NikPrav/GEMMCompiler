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
          iActs[1*IWS+:IWS]   -->|¯¯¯|--|¯¯¯|--|¯¯¯|--|¯¯¯|
                                 |___|  |___|  |___|  |___|
                                   |      |      |      |
             ...              -->|¯¯¯|--|¯¯¯|--|¯¯¯|--|¯¯¯|
                                 |___|  |___|  |___|  |___|
                                   |      |      |      |
       iActs[NUM_ROW*IWS+:IWS]-->|¯¯¯|--|¯¯¯|--|¯¯¯|--|¯¯¯|
                                 |___|  |___|  |___|  |___|
                                   |      |      |      |
                                   v      v      v      v
                                o_data o_data o_data o_data
                          [0*IWS+:IWS]               [NUM_ROW*IWS+:IWS]

            Every node has an output value;

    Author:      Jianming Tong (jianming.tong@gatech.edu) Anirudh Itagi (aitagi7@gatech.edu)
*/

module systolic_array_datapath#(
   parameter NUM_ROW            = 8,
   parameter NUM_COL            = 8,
   parameter DATA_WIDTH         = 8,
   parameter ACCU_DATA_WIDTH    = 32
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
    localparam  OUT_DATA_WIDTH = ACCU_DATA_WIDTH;

    /*
        ports
    */
    input                                                        clk;
    input                                                        rst_n;

    input  [NUM_COL                 -1: 0]                       i_cmd_top;
    input  [NUM_COL                 -1: 0]                       i_valid_top;
    input  [NUM_COL*ACCU_DATA_WIDTH -1: 0]                       i_data_top;
    input  [NUM_ROW                 -1: 0]                       i_cmd_left;
    input  [NUM_ROW                 -1: 0]                       i_valid_left;
    input  [NUM_ROW*DATA_WIDTH      -1: 0]                       i_data_left;
 
    output [NUM_COL*OUT_DATA_WIDTH  -1: 0]                       o_data;
    output [NUM_COL                 -1: 0]                       o_valid;
    /*
        inner logics
    */

    genvar gr,gc;
    genvar i,j;

    wire                                w_o_valid_top_down      [0 : NUM_ROW  ][0 : NUM_COL-1];
    wire    [ACCU_DATA_WIDTH    -1: 0]  w_o_data_top_down       [0 : NUM_ROW  ][0 : NUM_COL-1];
    wire                                w_o_cmd_top_down        [0 : NUM_ROW  ][0 : NUM_COL-1];
    wire                                w_o_valid_left_right    [0 : NUM_ROW-1][0 : NUM_COL  ];
    wire    [DATA_WIDTH         -1: 0]  w_o_data_left_right     [0 : NUM_ROW-1][0 : NUM_COL  ];
    wire                                w_o_cmd_left_right      [0 : NUM_ROW-1][0 : NUM_COL  ];

    /*
    INPUT FROM TOP
    */
    generate //added 
        for(gc=0; gc<NUM_COL; gc=gc+1)
        begin:assign_top_input
            assign w_o_cmd_top_down     [0][gc] = i_cmd_top         [ gc                    +:  1];
            assign w_o_valid_top_down   [0][gc] = i_valid_top       [ gc                    +:  1];
            assign w_o_data_top_down    [0][gc] = i_data_top        [(gc*ACCU_DATA_WIDTH)   +: ACCU_DATA_WIDTH];
        end
    endgenerate

    /*
    INPUT FROM LEFT
    */
    generate //added
    for(gr=0; gr<NUM_ROW; gr=gr+1)
    begin:assign_left_input
        assign w_o_cmd_left_right   [gr][0] = i_cmd_left        [ gr                    +:  1];
        assign w_o_valid_left_right [gr][0] = i_valid_left      [ gr                    +:  1];
        assign w_o_data_left_right  [gr][0] = i_data_left       [(gr*DATA_WIDTH)        +: DATA_WIDTH];
    end
    endgenerate

    /*
        instaniate 2D PE array
    */
    generate
        for(gr=0;gr<NUM_ROW;gr=gr+1)
        begin: pe_row
            for(gc=0;gc<NUM_COL;gc=gc+1)
            begin: pe_col
                systolic_array_pe#(
                    .DATA_WIDTH         (DATA_WIDTH                             ),
                    .ACCU_DATA_WIDTH    (ACCU_DATA_WIDTH                        ),
                    .LAST_ROW_PE        (!(NUM_ROW-1-gr)                        )
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
            assign o_data   [(gc*OUT_DATA_WIDTH)    +:  OUT_DATA_WIDTH] = w_o_data_top_down [NUM_ROW][gc];
            assign o_valid  [gc]                                        = w_o_valid_top_down[NUM_ROW][gc];
        end
    endgenerate

endmodule