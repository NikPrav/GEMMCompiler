`timescale 1ns / 1ps
module sram_mem_unit #(
   parameter word_size = 8;
   parameter memory_size = 256;
)(
    data_out, 
    data_in, 
    address, 
    clk, 
    write
);

  output [word_size-1: 0] data_out;
  input [word_size-1: 0] data_in;
  input [word_size-1: 0] address;
  input clk, write;
  reg [word_size-1: 0] memory [memory_size-1: 0];

  assign data_out = memory[address];

  always @ (posedge clk)
    if (write) memory[address] = data_in;
endmodule