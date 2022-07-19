`default_nettype none
`include "rtl/iWishbone.svh"

module mBlinkenLight #(
  parameter pLeds = 8
) (
  input logic clk,
  input logic rst,
  input iWishbone_Ctrl wb_c,
  input iWishbone_Peri wb_p,
  output logic [pLeds-1:0] blinkenlights
);
  logic [3:0] counter;
  logic request, we, dat_p, dat_c;

  assign blinkenlights = {counter, request, we, dat_c, dat_p};

  always_ff @(posedge clk) begin
    if (wb_c.stb) begin
      dat_c <= |wb_c.dat;
      dat_p <= 0;
      request <= 1;
    end
    if (wb_p.ack) begin
      dat_p <= |wb_p.dat;
      dat_c <= 0;
      request <= 1;
    end
    if (wb_c.stb || wb_p.ack) begin
      we <= wb_c.we;
      counter <= counter + 1;
    end

    if (rst) begin
      counter <= 4'b1111;
      request <= 1'b1; 
      {we, dat_p, dat_c} <= 0;
    end
  end

endmodule
