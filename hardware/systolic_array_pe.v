`timescale 1ns / 1ps
/*
    Top Module:  sysotlic_array_pe_os
    Data:        SA_IN_DATA_WIDTH is the width of input data -> OUT_WORD_SIZE is the width of output data.
    Timing:      Sequential Logic
    Reset:       Synchronized Reset [High negedge rst_n]

    Function:   Output Stationary.

                                  i_data_top (Weights/psum)
                                      |
                                      v
                                    +---+
                     i_data_left -->|   |--> o_data_right
                                    +---+
                                      |
                                      v
                                o_data_down

            
            Every node has an output value;

    Author:      Jianming Tong (jianming.tong@gatech.edu) Anirudh Itagi (aitagi7@gatech.edu)

    Note: 
    The accumulation part of the MAC operation involves adding the w_mult_result to the current 
    value stored in the r_stationary_data register. This register holds the running accumulation 
    of previous MAC operations. The sum of w_mult_result and r_stationary_data is assigned to 
    the w_accum_out wire, which is written back to r_stationary_data if enable is asserted. 
    Unless a flush command (i_cmd_top[1]) is received, the r_stationary_data register continues 
    to accumulate the MAC results from subsequent cycles. When a flush command is received, the 
    final accumulated value in r_stationary_data is propagated to the output (o_data_down) if the 
    current PE is in the last row of the systolic array. Otherwise, the accumulated value is passed 
    down to the next row (r_data_down).
*/



module systolic_array_pe_os #(
    parameter   SA_IN_DATA_WIDTH    = 8,
    parameter   SA_OUT_DATA_WIDTH   = 32, // By default the first level for the input data.
    parameter   ROW_ID              = 0,
    parameter   LAST_ROW_ID         = 3
)(
    // timing signals
    clk             ,
    rst_n           ,

    i_data_top      ,       // data signals
    i_valid_top     ,
    i_data_left     ,
    i_valid_left    ,
    o_data_right    ,
    o_valid_right   ,
    o_data_down     ,
    o_valid_down    ,


    i_cmd_top       ,   // command signals
    o_cmd_down      ,
    i_cmd_left      ,
    o_cmd_right
);

    /*
        parameters
    */
    localparam MULT_OUT_WIDTH  = (SA_IN_DATA_WIDTH*2);

    /*
        ports
    */

    input                                           clk;
    input                                           rst_n;

    input    [1:0]                                  i_cmd_top       ;   // i_cmd_top[0]==1 => store local result locally and accumulate the results , i_cmd_top[1]==1 => flush stored local result
    input    [SA_OUT_DATA_WIDTH -1: 0]              i_data_top      ;
    input                                           i_valid_top     ;
    input    [SA_IN_DATA_WIDTH  -1: 0]              i_data_left     ;
    input                                           i_cmd_left      ;   // 1'b1 means do the Accum
    input                                           i_valid_left    ;
    output   [SA_IN_DATA_WIDTH  -1: 0]              o_data_right    ;
    output                                          o_valid_right   ;
    output   [SA_OUT_DATA_WIDTH -1: 0]              o_data_down     ;
    output                                          o_valid_down    ;
    output   [1:0]                                  o_cmd_down      ;
    output                                          o_cmd_right     ;

    /*
        inner logics
    */

    wire                                            w_mac_en            ;
    reg      [SA_OUT_DATA_WIDTH -1: 0]              r_stationary_data   ;
    wire     [MULT_OUT_WIDTH    -1: 0]              w_mult_result       ;
    wire     [SA_OUT_DATA_WIDTH -1: 0]              w_accum_out         ;
    reg                                             r_cmd_right         ;
    reg                                             r_valid_right       ;
    reg      [SA_IN_DATA_WIDTH  -1: 0]              r_data_right        ;
    reg      [1:0]                                  r_cmd_down          ;
    reg                                             r_valid_down        ;
    reg      [SA_OUT_DATA_WIDTH -1: 0]              r_data_down         ;

    
    /*
        Multiply Top and Left inputs
        ACcumulate with r_stationary_data
    */
    assign  w_mac_en       =   i_cmd_left  &   i_cmd_top[0] & i_valid_left & i_valid_top;

    assign  w_mult_result  =   i_data_left * i_data_top[0  +:  SA_IN_DATA_WIDTH];
    assign  w_accum_out    =   w_mult_result  + r_stationary_data;

    always@(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            r_stationary_data   <=  0;
        end
        else
        begin
            if(i_cmd_top[1]==1)
            begin
                if(ROW_ID != 0)
                begin
                    r_stationary_data       <=  r_data_down;
                end
                else
                begin
                    if(i_cmd_top[0]==1)
                    begin
                        r_stationary_data   <=  0;
                    end
                end
            end
            else
            begin
                if(w_mac_en)
                begin
                    r_stationary_data       <=  w_accum_out;
                end
            end
        end
    end

    /*
        Register and send the Data from Left to Right
    */
    always@(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            r_valid_right   <=  0;
            r_data_right    <=  0;
            r_cmd_right     <=  0;
        end
        else
        begin
            r_valid_right   <=  i_valid_left;
            r_data_right    <=  i_data_left;
            r_cmd_right     <=  i_cmd_left;
        end
    end

    /*
        Register and send the Data from Top to Down
    */
    always@(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            r_valid_down    <=  0;
            r_data_down     <=  0;
            r_cmd_down      <=  0;
        end
        else
        begin
            r_valid_down    <=  i_valid_top;
            r_data_down     <=  i_data_top;
            r_cmd_down      <=  i_cmd_top;
        end
    end

    /*
        connect to output
    */
    assign o_cmd_right      =   r_cmd_right     ;
    assign o_valid_right    =   r_valid_right   ;
    assign o_data_right     =   r_data_right    ;
    assign o_cmd_down       =   r_cmd_down      ;
    assign o_valid_down     =   (ROW_ID == LAST_ROW_ID) ?   i_cmd_top[1]        :   r_valid_down        ;
    assign o_data_down      =   (i_cmd_top[1]==1)       ?   r_stationary_data   :   {1'b0, r_data_down}    ;

endmodule
