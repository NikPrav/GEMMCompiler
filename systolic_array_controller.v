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
 
 Author:      Jianming Tong (jianming.tong@gatech.edu) Anirudh Itagi (aitagi7@gatech.edu)
 */

module systolic_array_controller#(parameter NUM_ROW = 8,
                                  parameter NUM_COL = 8,
                                  parameter DATA_WIDTH = 8,
                                  parameter ACCU_DATA_WIDTH = 32,
                                  parameter LOG2_SRAM_BANK_DEPTH = 10,
                                  parameter SRAM_BANK_DEPTH = 8, 
                                  parameter SKEW_TOP_INPUT_EN = 1,
                                  parameter SKEW_LEFT_INPUT_EN = 1)
                                 (clk,
                                  rst_n,
                                  i_ctrl_state_to_ctrl,
                                  i_top_wr_en_to_ctrl,
                                  i_top_wr_addr_to_ctrl,
                                  i_left_wr_en_to_ctrl,
                                  i_left_wr_addr_to_ctrl,
                                  i_down_rd_en_to_ctrl,
                                  i_down_rd_addr_to_ctrl,
                                  i_top_sram_rd_start_addr,
                                  i_top_sram_rd_end_addr,
                                  i_left_sram_rd_start_addr,
                                  i_left_sram_rd_end_addr,
                                  o_top_rd_wr_en_from_ctrl,
                                  o_top_rd_wr_addr_from_ctrl,
                                  o_left_rd_wr_en_from_ctrl,
                                  o_left_rd_wr_addr_from_ctrl,
                                  o_down_rd_wr_en_from_ctrl,
                                  o_down_rd_wr_addr_from_ctrl,
                                  i_sa_datapath_valid_down_to_ctrl,
                                  o_valid_top_from_ctrl,
                                  o_valid_left_from_ctrl);
    
    /*
     localparam
     */
    localparam  OUT_DATA_WIDTH = ACCU_DATA_WIDTH;
    localparam  READ_ENABLE    = 1'b0;
    localparam  WRITE_ENABLE   = 1'b1;
    localparam  CTRL_WIDTH     = 4;
    
    /*
     ports
     */
    input                                                       clk                                 ;
    input                                                       rst_n                               ;
    input   [CTRL_WIDTH             -1: 0]                      i_ctrl_state_to_ctrl                ;
    input                                                       i_top_wr_en_to_ctrl                 ;
    input   [LOG2_SRAM_BANK_DEPTH     -1: 0]                    i_top_wr_addr_to_ctrl               ; 
    input                                                       i_left_wr_en_to_ctrl                ;
    input   [LOG2_SRAM_BANK_DEPTH    -1: 0]                      i_left_wr_addr_to_ctrl             ;
    input                                                       i_down_rd_en_to_ctrl                ;
    input   [LOG2_SRAM_BANK_DEPTH   -1: 0]                      i_down_rd_addr_to_ctrl              ;
    
    input   [LOG2_SRAM_BANK_DEPTH   -1: 0]                      i_top_sram_rd_start_addr            ;
    input   [LOG2_SRAM_BANK_DEPTH   -1: 0]                      i_top_sram_rd_end_addr              ;
    input   [LOG2_SRAM_BANK_DEPTH   -1: 0]                      i_left_sram_rd_start_addr           ;
    input   [LOG2_SRAM_BANK_DEPTH   -1: 0]                      i_left_sram_rd_end_addr             ;
    
    output                                                      o_top_rd_wr_en_from_ctrl            ;
    output  [LOG2_SRAM_BANK_DEPTH   -1: 0]                      o_top_rd_wr_addr_from_ctrl          ;
    output                                                      o_left_rd_wr_en_from_ctrl           ;
    output  [LOG2_SRAM_BANK_DEPTH   -1: 0]                      o_left_rd_wr_addr_from_ctrl         ;
    output  [NUM_COL                -1: 0]                      o_down_rd_wr_en_from_ctrl           ;
    output  [LOG2_SRAM_BANK_DEPTH   -1: 0]                      o_down_rd_wr_addr_from_ctrl         ;
    input   [NUM_COL                -1: 0]                      i_sa_datapath_valid_down_to_ctrl    ;
    output  [NUM_COL                -1: 0]                      o_valid_top_from_ctrl               ;
    output  [NUM_ROW                -1: 0]                      o_valid_left_from_ctrl              ;
    
    
    integer  i_r, i_c;
    genvar   gr, gc;
    
    localparam IDLE   = 0;
    localparam STEADY = 1;
    localparam DRAIN  = 3;
    
    reg     [LOG2_SRAM_BANK_DEPTH   -1: 0]  r_i_down_wr_addr            ;
    reg                                     r_top_rd_wr_en_from_ctrl    ;
    reg     [LOG2_SRAM_BANK_DEPTH   -1: 0]  r_top_rd_wr_addr_from_ctrl  ;
    reg                                     r_left_rd_wr_en_from_ctrl   ;
    reg     [LOG2_SRAM_BANK_DEPTH   -1: 0]  r_left_rd_wr_addr_from_ctrl ;
    reg                                     r_down_rd_wr_en_from_ctrl;

    reg     [NUM_COL                -1: 0]  r_valid_top_from_ctrl       ;
    reg     [NUM_ROW                -1: 0]  r_valid_left_from_ctrl      ;
    wire                                    w_sa_output_rdy;

    integer top_count, left_count, down_count;
    reg top_read_done, left_read_done;
    
    always@(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            r_i_down_wr_addr <= 0;
        end
        else
        begin
            if (i_ctrl_state_to_ctrl == IDLE)
            begin
                r_top_rd_wr_en_from_ctrl  <= {NUM_COL{READ_ENABLE}}     ;
                r_left_rd_wr_en_from_ctrl <= {NUM_ROW{READ_ENABLE}}     ;
                r_i_down_wr_addr          <= 0;
                
                r_top_rd_wr_addr_from_ctrl <= i_top_sram_rd_start_addr;
                r_left_rd_wr_addr_from_ctrl <= i_left_sram_rd_start_addr;

                top_count <= 0;
                left_count <= 0;
                down_count <= 0;

                top_read_done <= 0;
                left_read_done <= 0;
            end
            // DELETED WARMUP STAGE
            else if (i_ctrl_state_to_ctrl == STEADY)
            
            begin
            
            if (r_top_rd_wr_addr_from_ctrl < i_top_sram_rd_end_addr && (top_read_done != 1))
            begin
                r_top_rd_wr_en_from_ctrl <= {NUM_COL{READ_ENABLE}};
                r_valid_top_from_ctrl    <= ~0;

                if (r_top_rd_wr_addr_from_ctrl == i_top_sram_rd_end_addr - 1) begin 
                    r_top_rd_wr_addr_from_ctrl <= r_top_rd_wr_addr_from_ctrl;
                    top_read_done <= 1;
                end 
                else begin 
                    r_top_rd_wr_addr_from_ctrl <=  r_top_rd_wr_addr_from_ctrl + 1;
                end
            end
            else
            begin
                r_top_rd_wr_addr_from_ctrl <= 0;
                r_valid_top_from_ctrl      <= 0;
            end
            
            if (r_left_rd_wr_addr_from_ctrl  < i_left_sram_rd_end_addr  && (left_read_done != 1))
            begin
                r_left_rd_wr_en_from_ctrl <= {NUM_ROW{READ_ENABLE}};
                r_valid_left_from_ctrl    <= ~0;

                if (r_left_rd_wr_addr_from_ctrl == i_left_sram_rd_end_addr - 1) begin 
                    r_left_rd_wr_addr_from_ctrl <= r_left_rd_wr_addr_from_ctrl;
                    left_read_done <= 1;
                end 
                else begin 
                    r_left_rd_wr_addr_from_ctrl <=  r_left_rd_wr_addr_from_ctrl + 1;
                end
            end
            else
            begin
                r_left_rd_wr_addr_from_ctrl <= 0;
                r_valid_left_from_ctrl      <= 0;
            end
        end
        
            else if (i_ctrl_state_to_ctrl == DRAIN)
            begin

                // Wait for all the data to drain; takes NUM_ROW clock cycles 
                if (i_sa_datapath_valid_down_to_ctrl[NUM_COL -1] == 1 && down_count < NUM_ROW) begin 
                    if (down_count == NUM_ROW - 1) begin
                        r_down_rd_wr_en_from_ctrl <= {NUM_COL{READ_ENABLE}};
                    end else begin 
                        r_down_rd_wr_en_from_ctrl <= {NUM_COL{WRITE_ENABLE}};
                        down_count <= down_count + 1;
                    end

                    r_i_down_wr_addr <= r_i_down_wr_addr - 1;
                end else if (down_count == NUM_ROW) begin
                    r_i_down_wr_addr <= 0;
                end
                else begin 
                    r_i_down_wr_addr <= NUM_ROW;
                    r_down_rd_wr_en_from_ctrl <= {NUM_COL{READ_ENABLE}};
                end
            end
    end
    end
    
    // CHANGED: on IDLE, assign o_top_rd_wr_addr_from_ctrl to the input wr_addr from top (TB input)
    
    assign  o_top_rd_wr_addr_from_ctrl    = (i_ctrl_state_to_ctrl == IDLE) ? i_top_wr_addr_to_ctrl   : r_top_rd_wr_addr_from_ctrl;
    // assign  o_top_rd_wr_addr_from_ctrl = (i_ctrl_state_to_ctrl == IDLE) ? i_top_sram_rd_start_addr   : r_top_rd_wr_addr_from_ctrl;
    assign  o_top_rd_wr_en_from_ctrl      = (i_ctrl_state_to_ctrl == IDLE) ? i_top_wr_en_to_ctrl        : r_top_rd_wr_en_from_ctrl;
    
    assign  o_left_rd_wr_addr_from_ctrl    = (i_ctrl_state_to_ctrl == IDLE) ? i_left_wr_addr_to_ctrl  : r_left_rd_wr_addr_from_ctrl;
    // assign  o_left_rd_wr_addr_from_ctrl = (i_ctrl_state_to_ctrl == IDLE) ? i_left_sram_rd_start_addr  : r_left_rd_wr_addr_from_ctrl;
    assign  o_left_rd_wr_en_from_ctrl      = (i_ctrl_state_to_ctrl == IDLE) ? i_left_wr_en_to_ctrl       : r_left_rd_wr_en_from_ctrl;
    
    assign  o_valid_top_from_ctrl  = r_valid_top_from_ctrl;
    assign  o_valid_left_from_ctrl = r_valid_left_from_ctrl;

    assign  o_down_rd_wr_en_from_ctrl = ((down_count !== 0) && (down_count <= NUM_ROW - 1)) ? r_down_rd_wr_en_from_ctrl : (((i_ctrl_state_to_ctrl == DRAIN) && (i_sa_datapath_valid_down_to_ctrl[NUM_COL-1] == 1))?1:0);

    // assign  o_down_rd_wr_en_from_ctrl = (i_ctrl_state_to_ctrl == IDLE) ? i_down_rd_en_to_ctrl : r_down_rd_wr_en_from_ctrl; 
    assign  o_down_rd_wr_addr_from_ctrl = (i_down_rd_en_to_ctrl == 0) ?  r_i_down_wr_addr    :   i_down_rd_addr_to_ctrl;
    
endmodule
