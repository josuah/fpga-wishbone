`default_nettype none
`include "rtl/iWishbone.svh"

module mDebug (
  input logic clk,
  input logic rst,
  output  iWishbone_Peri wb_p,
  input iWishbone_Ctrl wb_c,
  output  logic[7:0] debug
);
  logic unused = |{ wb_c.adr };
  assign wb_p.dat = 0;
  assign wb_p.ack = wb_c.stb;

  always_ff @(posedge clk) begin
    if (wb_c.stb && wb_c.we) begin
      debug <= wb_c.dat;
    end

    if (rst) begin
      debug <= 8'b11011011;
    end
  end
endmodule
