`default_nettype none

module peri_draw_line #(
  parameter ScreenWidth = 100,
  parameter ScreenHeight = 50,
  parameter CoordSz = 16
) (
  input clk_i,
  input rst_ni,

  // wishbone b4 peripheral
  input wb_we_i,
  input wb_stb_i,
  output wb_ack_o,
  input [7:0] wb_adr_i,
  input [7:0] wb_dat_i,
  output [7:0] wb_dat_o,

  // memory framebuffer i/o
  output [CoordSz-1:0] dot_row_o,
  output [CoordSz-1:0] dot_col_o,
  output dot_valid_o
);
  assign wb_ack_o = wb_stb_i;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
    end else begin
    end
  end

  // divide the input clock
  always_comb begin
  end

endmodule
