`timescale 1ns/1ps

`define PERIOD 10

module new_tb();
        parameter                                       NUM_ROW              = 4;
        parameter                                       NUM_COL              = 4;
        parameter                                       DATA_WIDTH           = 16;
        parameter                                       ACCU_DATA_WIDTH      = 16;
        parameter                                       OUT_DATA_WIDTH       = ACCU_DATA_WIDTH;
        parameter                                       LOG2_SRAM_BANK_DEPTH = 4;
        parameter                                       CTRL_WIDTH           = 4;
        parameter                                       SRAM_BANK_DEPTH      = 4; 
        parameter MEM_DEPTH = 1024;

        reg                                              clk              = 0;
        reg                                              rst_n            = 0;

        reg                                             r_i_top_wr_en    = 0;
        wire                                            w_i_top_wr_en;

        reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_top_wr_addr  = 0;
        wire    [LOG2_SRAM_BANK_DEPTH       -1: 0]      w_i_top_wr_addr;
        
        reg     [NUM_COL*DATA_WIDTH         -1: 0]      r_i_top_wr_data  = 0;
        wire    [NUM_COL*DATA_WIDTH         -1: 0]      w_i_top_wr_data;

        reg                                              r_i_left_wr_en   = 0;
        wire                                             w_i_left_wr_en;

        reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_left_wr_addr = 0;
        wire    [LOG2_SRAM_BANK_DEPTH       -1: 0]      w_i_left_wr_addr;

        reg     [NUM_ROW*DATA_WIDTH         -1: 0]      r_i_left_wr_data = 0;
        wire    [NUM_ROW*DATA_WIDTH         -1: 0]      w_i_left_wr_data;

        reg                                             r_i_down_rd_en   = 0;
        wire                                             w_i_down_rd_en;
        
        reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_down_rd_addr = 0;
        wire     [LOG2_SRAM_BANK_DEPTH       -1: 0]      w_i_down_rd_addr;

        
        reg     [CTRL_WIDTH                 -1: 0]      r_i_ctrl_state              = 0;
        wire     [CTRL_WIDTH                 -1: 0]      w_i_ctrl_state;

        reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_top_sram_rd_start_addr  = 0;
        wire    [LOG2_SRAM_BANK_DEPTH       -1: 0]      w_i_top_sram_rd_start_addr;

        reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_top_sram_rd_end_addr    = 0;
        wire    [LOG2_SRAM_BANK_DEPTH       -1: 0]      w_i_top_sram_rd_end_addr;

        reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_left_sram_rd_start_addr = 0;
        wire    [LOG2_SRAM_BANK_DEPTH       -1: 0]      w_i_left_sram_rd_start_addr;

        reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_left_sram_rd_end_addr   = 0;
        wire    [LOG2_SRAM_BANK_DEPTH       -1: 0]      w_i_left_sram_rd_end_addr;

        reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_down_sram_rd_start_addr = 0;
        wire    [LOG2_SRAM_BANK_DEPTH       -1: 0]      w_i_down_sram_rd_start_addr;

        reg     [LOG2_SRAM_BANK_DEPTH       -1: 0]      r_i_down_sram_rd_end_addr   = 0;
        wire    [LOG2_SRAM_BANK_DEPTH       -1: 0]      w_i_down_sram_rd_end_addr;

        wire     [NUM_COL*OUT_DATA_WIDTH     -1: 0]      w_o_down_rd_data;

        parameter IDLE   = 0;
        parameter WARMUP = 1;
        parameter STEADY = 2;
        parameter DRAIN  = 3;

        // Inst_reader variables //
        parameter INST_WIDTH            = 32;
        parameter INST_MEMORY_SIZE      = 2048;
        parameter LOG2_INST_MEMORY_SIZE = 12;

        parameter OPCODE_WIDTH          = 4;
        parameter BUF_ID_WIDTH          = 2;
        parameter MEM_LOC_WIDTH         = 26;

        parameter MEM_LOC_ARRAY_INDEX   = MEM_LOC_WIDTH;
        parameter BUF_ID_ARRAY_INDEX    = MEM_LOC_ARRAY_INDEX + BUF_ID_WIDTH;
        parameter OPCODE_ARRAY_INDEX    = BUF_ID_ARRAY_INDEX + OPCODE_WIDTH;

        parameter opcode_LD             = 4'b0010;
        parameter opcode_ST             = 4'b0011;
        parameter opcode_GEMM           = 4'b0100;
        parameter opcode_DRAINSYS       = 4'b0101;

        wire [OPCODE_WIDTH - 1: 0]   opcode;
        wire [BUF_ID_WIDTH - 1: 0]   buf_id;
        wire [MEM_LOC_WIDTH - 1: 0]  mem_loc;

        always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin 

                        r_i_ctrl_state <= 0;

                        r_i_top_wr_en <= 0;
                        r_i_top_wr_addr <= 0;
                        r_i_top_wr_data <= 0;

                        r_i_left_wr_en <= 0;
                        r_i_left_wr_addr <= 0;
                        r_i_left_wr_data <= 0; 

                        r_i_down_rd_en <= 0;
                        r_i_down_rd_addr <= 0;

                        r_i_down_sram_rd_start_addr <= 0;
                        r_i_top_sram_rd_start_addr <= 0;
                        r_i_left_sram_rd_start_addr <= 0;

                        r_i_down_sram_rd_end_addr <= 0;
                        r_i_top_sram_rd_end_addr <= 0;
                        r_i_left_sram_rd_end_addr <= 0;

                end else begin 

                        r_i_ctrl_state <= w_i_ctrl_state;

                        r_i_left_wr_en <= w_i_left_wr_en;
                        r_i_left_wr_addr <= w_i_left_wr_addr;
                        r_i_left_wr_data <= w_i_left_wr_data;

                        r_i_top_wr_en <= w_i_top_wr_en;
                        r_i_top_wr_addr <= w_i_top_wr_addr;
                        r_i_top_wr_data <= w_i_top_wr_data;

                        r_i_down_rd_en <= w_i_down_rd_en;
                        r_i_down_rd_addr <= w_i_down_rd_addr;

                        r_i_top_sram_rd_start_addr <= w_i_top_sram_rd_start_addr;
                        r_i_left_sram_rd_start_addr <= w_i_left_sram_rd_start_addr;
                        r_i_down_sram_rd_start_addr <= w_i_down_sram_rd_start_addr;

                        r_i_top_sram_rd_end_addr <= w_i_top_sram_rd_end_addr;
                        r_i_left_sram_rd_end_addr <= w_i_left_sram_rd_end_addr;
                        r_i_down_sram_rd_end_addr <= w_i_down_sram_rd_end_addr;
                        
                end
        end

        inst_reader #(
                .INST_WIDTH                     (INST_WIDTH),
                .INST_MEMORY_SIZE               (INST_MEMORY_SIZE),
                .OPCODE_WIDTH                   (OPCODE_WIDTH),
                .BUF_ID_WIDTH                   (BUF_ID_WIDTH),
                .MEM_LOC_WIDTH                  (MEM_LOC_WIDTH),

                .OPCODE_ARRAY_INDEX             (OPCODE_ARRAY_INDEX),
                .BUF_ID_ARRAY_INDEX             (BUF_ID_ARRAY_INDEX),
                .MEM_LOC_ARRAY_INDEX            (MEM_LOC_ARRAY_INDEX),

                .opcode_LD                      (opcode_LD),
                .opcode_ST                      (opcode_ST),
                .opcode_GEMM                    (opcode_GEMM),
                .opcode_DRAINSYS                (opcode_DRAINSYS),

                .NUM_ROW                        (NUM_ROW),
                .NUM_COL                        (NUM_COL),
                .DATA_WIDTH                     (DATA_WIDTH),
                .CTRL_WIDTH                     (CTRL_WIDTH),
                .ACCU_DATA_WIDTH                (ACCU_DATA_WIDTH),
                .LOG2_SRAM_BANK_DEPTH           (LOG2_SRAM_BANK_DEPTH),
                .SRAM_BANK_DEPTH                (SRAM_BANK_DEPTH), 
                .SKEW_TOP_INPUT_EN              (1),
                .SKEW_LEFT_INPUT_EN             (1)

        )inst_reader_in_new_top(
                .opcode                         (opcode),
                .buf_id                         (buf_id),
                .mem_loc                        (mem_loc),
                
                .clk                            (clk),
                .rst_n                          (rst_n),
                .i_top_wr_en                    (w_i_top_wr_en),
                .i_top_wr_data                  (w_i_top_wr_data),
                .i_top_wr_addr                  (w_i_top_wr_addr),
                .i_left_wr_en                   (w_i_left_wr_en),
                .i_left_wr_data                 (w_i_left_wr_data),
                .i_left_wr_addr                 (w_i_left_wr_addr),
                .i_down_rd_en                   (w_i_down_rd_en),
                .i_down_rd_addr                 (w_i_down_rd_addr),
                .o_down_rd_data                 (w_o_down_rd_data), //unaffected
                .i_ctrl_state                   (w_i_ctrl_state),
                .i_top_sram_rd_start_addr       (w_i_top_sram_rd_start_addr),
                .i_top_sram_rd_end_addr         (w_i_top_sram_rd_end_addr),
                .i_left_sram_rd_start_addr      (w_i_left_sram_rd_start_addr),
                .i_left_sram_rd_end_addr        (w_i_left_sram_rd_end_addr),
                .i_down_sram_rd_start_addr      (w_i_down_sram_rd_start_addr),
                .i_down_sram_rd_end_addr        (w_i_down_sram_rd_end_addr)
        );

        systolic_array_top #(
                .NUM_ROW                        (NUM_ROW),
                .NUM_COL                        (NUM_COL),
                .DATA_WIDTH                     (DATA_WIDTH),
                .ACCU_DATA_WIDTH                (ACCU_DATA_WIDTH),
                .LOG2_SRAM_BANK_DEPTH           (LOG2_SRAM_BANK_DEPTH),
                .SRAM_BANK_DEPTH                (SRAM_BANK_DEPTH), 
                .SKEW_TOP_INPUT_EN              (1) 
        )systolic_array_top_in_new_tb(
                .clk                            (clk),
                .rst_n                          (rst_n),
                .i_top_wr_en                    (r_i_top_wr_en),
                .i_top_wr_data                  (r_i_top_wr_data),
                .i_top_wr_addr                  (r_i_top_wr_addr),
                .i_left_wr_en                   (r_i_left_wr_en),
                .i_left_wr_data                 (r_i_left_wr_data),
                .i_left_wr_addr                 (r_i_left_wr_addr),
                .i_down_rd_en                   (r_i_down_rd_en),
                .i_down_rd_addr                 (r_i_down_rd_addr),
                .o_down_rd_data                 (w_o_down_rd_data),
                .i_ctrl_state                   (r_i_ctrl_state),
                .i_top_sram_rd_start_addr       (r_i_top_sram_rd_start_addr),
                .i_top_sram_rd_end_addr         (r_i_top_sram_rd_end_addr),
                .i_left_sram_rd_start_addr      (r_i_left_sram_rd_start_addr),
                .i_left_sram_rd_end_addr        (r_i_left_sram_rd_end_addr),
                .i_down_sram_rd_start_addr      (r_i_down_sram_rd_start_addr),
                .i_down_sram_rd_end_addr        (r_i_down_sram_rd_end_addr)
        );

        initial
        begin
                rst_n = 0;
                #(`PERIOD)
                rst_n = 1;
        end

        // Free running clk
        always #(`PERIOD/2) clk = ~clk;

endmodule