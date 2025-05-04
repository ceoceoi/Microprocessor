`timescale 1ns / 1ps

module Register #(
    parameter bits = 32
) (
    clk,
    rst_n,
    clear,
    en,
    d,
    q
);
    input logic clk;
    input logic rst_n;
    input logic clear;
    input logic en;
    input logic [bits-1:0] d;
    output logic [bits-1:0] q;

  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) q <= '0;
    else if (clear) q <= '0;
    else if (en) q <= d;
    else q <= q;
  end
  endmodule