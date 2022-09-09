`default_nettype none

module peri_draw_line #(
  parameter AddrSz = 4,
  parameter ScreenW = 100,
  parameter ScreenH = 50,
  parameter CoordSz = 8
) (
  input  clk_i,
  input  rst_ni,

  // wishbone b4 peripheral
  input  wb_we_i,
  input  wb_stb_i,
  output wb_ack_o,
  input  [AddrSz-1:0] wb_adr_i,
  input  [7:0] wb_dat_i,
  output [7:0] wb_dat_o,

  // memory framebuffer i/o
  output pixel_req_o,
  output [CoordSz-1:0] pixel_x_o,
  output [CoordSz-1:0] pixel_y_o
);
  typedef struct packed {
    logic [CoordSz-1:0] beg_x, beg_y, end_x, end_y;
    logic run;
  } reg_bank_t;

  logic [CoordSz-1:0] accu_d, accu_q;
  logic [CoordSz-1:0] pixel_x_d, pixel_x_q;
  logic [CoordSz-1:0] pixel_y_d, pixel_y_q;
  reg_bank_t regs;

  assign wb_ack_o = wb_stb_i;
  assign pixel_x_o = pixel_x_q;
  assign pixel_y_o = pixel_y_q;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      pixel_x_q <= 0;
      pixel_y_q <= 0;
    end else begin
      pixel_x_q <= pixel_x_d;
      pixel_y_q <= pixel_y_d;
    end
  end

  always_comb begin
    pixel_x_d = pixel_x_q;
    pixel_y_d = pixel_y_q;
  end

endmodule
