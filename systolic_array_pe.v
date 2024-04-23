`timescale 1ns / 1ps
/*
 Top Module:  sysotlic_array_pe
 Data:        DATA_WIDTH is the width of input data -> OUT_WORD_SIZE is the width of output data.
 Format:      OUT_WORD_SIZE = DATA_WIDTH << 1; beacuse multiplication happen inside
 Timing:      Sequential Logic
 Reset:       Synchronized Reset [High negedge rst_n]
 Dummy Data:  {DATA_WIDTH{1'b0}}
 
 Function:   Output/Weight Stationary.
 
 i_data_top   i_psum_down (accumulated result)
 |        |
 v        v
 (weights and input)  i_data_left -->|¯¯¯¯¯¯¯¯¯¯¯¯|--> o_data_right
 |____________|
 |        |
 v        v
 o_data_down    o_psum_down (post-accumulation result)
 
 
 Every node has an output value;
 */



module systolic_array_pe #(parameter DATA_WIDTH = 8,
                           parameter ACCU_DATA_WIDTH = 32, // By default the frist level for the input data.
                           parameter LAST_ROW_PE = 0)
                         (clk,
                           rst_n,
                           i_data_top,                     // data signals
                           i_valid_top,
                           i_data_left,
                           i_valid_left,
                           o_data_right,
                           o_valid_right,
                           o_data_down,
                           o_valid_down,
                           i_cmd_top,                      // command signals
                           o_cmd_down,
                           i_cmd_left,
                           o_cmd_right);
    
    /*
     parameters
     */
    localparam OUT_DATA_WIDTH = ACCU_DATA_WIDTH;
    localparam MULT_OUT_WIDTH = (DATA_WIDTH*2);
    
    
    /*
     ports
     */
    
    input                                           clk;
    input                                           rst_n;
    
    input                                           i_cmd_top       ;   // 1'b1 means store the external weights inside.
    input    [ACCU_DATA_WIDTH   -1: 0]              i_data_top      ;
    input                                           i_valid_top     ;
    input    [DATA_WIDTH        -1: 0]              i_data_left     ;
    input                                           i_cmd_left      ;   // 1'b1 means do the Accum
    input                                           i_valid_left    ;
    output   [DATA_WIDTH        -1: 0]              o_data_right    ;
    output                                          o_valid_right   ;
    output   [OUT_DATA_WIDTH    -1: 0]              o_data_down     ;
    output                                          o_valid_down    ;
    output                                          o_cmd_down      ;
    output                                          o_cmd_right     ;
    
    /*
     inner logics
     */
    
    reg      [DATA_WIDTH        -1: 0]              r_stationary_data_top;
    
    wire                                            w_stationary_valid_top;
    reg                                             r_stationary_valid_top;
    wire                                            w_mac_en;
    
    wire     [MULT_OUT_WIDTH    -1: 0]              w_mult_out;
    wire     [OUT_DATA_WIDTH    -1: 0]              w_accum_out;
    reg      [OUT_DATA_WIDTH    -1: 0]              r_accum_out;
    
    reg      [DATA_WIDTH        -1: 0]              r_data_right;
    reg                                             r_valid_right;
    reg                                             r_valid_down;
    reg                                             r_cmd_down;
    reg                                             r_cmd_right;
    
    /*
     Register the stationary data from top
     */
    assign  w_stationary_valid_top = i_valid_top & i_cmd_top;
    
    always@(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            r_stationary_data_top  <= 0;
            r_stationary_valid_top <= 0;
        end
        else
        begin
            if (w_stationary_valid_top == 1 & r_stationary_valid_top == 0)
            begin
                r_stationary_valid_top <= 1;
                r_stationary_data_top  <= i_data_top[0 +: DATA_WIDTH];
            end
        end
    end
    
    /*
     MAC - Multiplication + Accumulation
     */
    assign  w_mac_en = i_cmd_left  & r_stationary_valid_top;
    
    assign  w_mult_out  = i_data_left * r_stationary_data_top;
    assign  w_accum_out = w_mult_out + i_data_top;
    
    always@(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            r_accum_out <= 0;
        end
        else
        begin
            if (w_stationary_valid_top)
            begin
                r_accum_out <= i_data_top;
            end
            else
            begin
                if (w_mac_en)
                begin
                    r_accum_out <= w_accum_out;
                end
            end
        end
    end
    
    
    /*
     Register and send the Data from Top to Bottom
     */
    always@(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            r_valid_down <= 0;
            r_cmd_down   <= 0;
        end
        else
        begin
            r_valid_down <= i_valid_top;
            r_cmd_down   <= i_cmd_top & r_stationary_valid_top;
        end
    end
    
    /*
     Register and send the Data from Left to Right
     */
    always@(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            r_valid_right <= 0;
            r_data_right  <= 0;
            r_cmd_right   <= 0;
        end
        else
        begin
            r_valid_right <= i_valid_left;
            r_data_right  <= i_data_left;
            r_cmd_right   <= i_cmd_left;
        end
    end
    
    
    assign o_data_right  = r_data_right;
    assign o_valid_right = r_valid_right;
    assign o_data_down   = r_accum_out;
    
    generate
    if (LAST_ROW_PE == 0)
    begin
        assign o_valid_down = r_valid_down;
    end
    else
    begin
        assign o_valid_down = r_valid_right;
    end
    endgenerate
    assign o_cmd_down  = r_cmd_down;
    assign o_cmd_right = r_cmd_right;
    
endmodule
