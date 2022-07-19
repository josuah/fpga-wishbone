`default_nettype none
`include "rtl/iWishbone.svh"
`include "rtl/iSpi.svh"

module top#(
//  parameter pCpuHz = 48_000_000,
  parameter pAddrLen = 4
)(
  input logic clk,
  input logic spi_sck,
  input logic spi_csn,
  input logic spi_sdi,
  output  logic spi_sdo,
  output  logic[6:0] charlieplex_o, charlieplex_oe,
  output  logic[2:0] rgb,
  output  logic[7:0] debug
);
  logic rst_n = 0;
  logic rst = !rst_n;

  iSpi_Ctrl spi_c;
  iSpi_Peri spi_p;

  iWishbone_Ctrl wbc_c;
  iWishbone_Peri wbc_p;

  assign charlieplex_o = 0;
  assign charlieplex_oe = 0;

  assign spi_sdo = spi_p.dat;
  assign spi_c.dat = spi_sdi;
  assign spi_c.sck = spi_sck;
  assign spi_c.csn = spi_csn;

  logic unused = &{ wbc_c[13] };
  mWishboneCtrlSpi mwcs(
    .clk, .rst, .wb_p(wbc_p), .wb_c(wbc_c),
    .spi_p, .spi_c,
    .debug
  );

//  mBlinkenLight mbl(
//    .clk, .rst, .wb_c(wbc_p), .wb_p(wbc_p),
//    .blinkenlights(debug)
//  );

  iWishbone_Ctrl wb0_c;
  iWishbone_Peri wb0_p;
  assign wb0_c[13] = 1'b1;
  mRgbLed mp0(
    .clk, .rst, .wb_p(wb0_p), .wb_c(wb0_c),
    .rgb(rgb)
  );
  assign wb0_c.dat = wbc_c.dat;
  assign wb0_c.adr = wbc_c.adr;
  assign wb0_c.we = wbc_c.we;

//  iWishbone_Ctrl wb1_c;
//  iWishbone_Peri wb1_p;
//  assign wb1_c[13] = 0;
//  mDebug mp1(
//    .clk, .rst, .wb_p(wb1_p), .wb_c(wb1_c),
//    .debug(debug)
//  );
//  assign wb1_c.dat = wbc_c.dat;
//  assign wb1_c.adr = wbc_c.adr;
//  assign wb1_c.we = wbc_c.we;
//  assign wb0_c[13] = 1'b1;

//  iWishbone_Ctrl wb2_c;
//  iWishbone_Peri wb2_p;
//  mCharlieplex#(.pClkHz(pCpuHz)) wb2(
//    .clk, .rst, .wb_p(wb2_p), .wb_p(wb2_c),
//    .charlieplex_o, .charlieplex_oe
//  );
//  assign wb2_c.dat = wbc_c.dat;
//  assign wb2_c.adr = wbc_c.adr;
//  assign wb2_c.we = wbc_c.we;

  always_comb begin
    case (wbc_c.adr)
    pAddrLen'(0): begin
      wbc_p.dat = wb0_p.dat;
      wbc_p.ack = wb0_p.ack;
      wb0_c.stb = wbc_c.stb;
    end
//    pAddrLen'(1): begin
//      wbc_p.dat = wb1_p.dat;
//      wbc_p.ack = wb1_p.ack;
//      wb1_c.stb = wbc_c.stb;
//    end
    default: begin
      wbc_p.dat = 8'b00000000;
      wbc_p.ack = 1'b0;
      wb0_c.stb = 0;
//      wb1_c.stb = 0;
    end
    endcase
  end

  always_ff @(posedge clk) begin
    rst_n <= 1;
  end
endmodule
