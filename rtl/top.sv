`default_nettype none

module top#(
//  parameter CpuHz = 48_000_000,
  parameter AddrLen = 4
) (
  input logic clk_i,
  input logic spi_sck,
  input logic spi_csn,
  input logic spi_sdi,
  output  logic spi_sdo,
  output  logic[6:0] charlieplex_o, charlieplex_oe,
  output  logic[2:0] rgb,
  output  logic[7:0] debug
);
  logic rst_ni_n = 0;
  logic rst_ni = !rst_ni_n;

  iSpi_Ctrl spi_c;
  iSpi_Peri spi_p;

  iWishbone_Ctrl wbc_c;
  iWishbone_Peri wbc_p;

  assign charlieplex_o = 0;
  assign charlieplex_oe = 0;

  assign spi_sdo = spi_dat;
  assign spi_dat = spi_sdi;
  assign spi_sck = spi_sck;
  assign spi_csn = spi_csn;

  logic unused = &{ wbc_c[13] };
  mWishboneCtrlSpi mwcs(
    .clk_i, .rst_ni, .wb_p(wbc_p), .wb_c(wbc_c),
    .spi_p, .spi_c,
    .debug
  );

//  mBlinkenLight mbl(
//    .clk_i, .rst_ni, .wb_c(wbc_p), .wb_p(wbc_p),
//    .blinkenlights(debug)
//  );

  iWishbone_Ctrl wb0_c;
  iWishbone_Peri wb0_p;
  assign wb0_c[13] = 1'b1;
  mRgbLed mp0(
    .clk_i, .rst_ni, .wb_p(wb0_p), .wb_c(wb0_c),
    .rgb(rgb)
  );
  assign wb0_c.dat = wbc_c.dat;
  assign wb0_c.adr = wbc_c.adr;
  assign wb0_c.we = wbc_c.we;

//  iWishbone_Ctrl wb1_c;
//  iWishbone_Peri wb1_p;
//  assign wb1_c[13] = 0;
//  mDebug mp1(
//    .clk_i, .rst_ni, .wb_p(wb1_p), .wb_c(wb1_c),
//    .debug(debug)
//  );
//  assign wb1_c.dat = wbc_c.dat;
//  assign wb1_c.adr = wbc_c.adr;
//  assign wb1_c.we = wbc_c.we;
//  assign wb0_c[13] = 1'b1;

//  iWishbone_Ctrl wb2_c;
//  iWishbone_Peri wb2_p;
//  mCharlieplex#(.ClkHz(CpuHz)) wb2(
//    .clk_i, .rst_ni, .wb_p(wb2_p), .wb_p(wb2_c),
//    .charlieplex_o, .charlieplex_oe
//  );
//  assign wb2_c.dat = wbc_c.dat;
//  assign wb2_c.adr = wbc_c.adr;
//  assign wb2_c.we = wbc_c.we;

  always_comb begin
    case (wbc_c.adr)
    AddrLen'(0): begin
      wbc_p.dat = wb0_p.dat;
      wbc_p.ack = wb0_p.ack;
      wb0_c.stb = wbc_c.stb;
    end
//    AddrLen'(1): begin
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

  always_ff @(posedge clk_i) begin
    rst_ni_n <= 1;
  end
endmodule
