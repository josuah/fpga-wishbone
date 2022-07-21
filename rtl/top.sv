`default_nettype none

module top#(
//  parameter int CpuHz = 48_000_000,
  parameter int AddrW = 4,
  parameter int DataW = 8
) (
  input clk_i,

  // spi peripheral
  input spi_sck_i,
  input spi_csn_i,
  input spi_data_i,
  output spi_data_o,

  // led gpio
  output [2:0] rgb_o,
  output [7:0] debug_o

  // charlieplexed gpio
  output [6:0] charlieplex_o,
  output [6:0] charlieplex_oe,
);
  logic rst_ni;

  initial rst_ni = 0;

  assign charlieplex_o = 0;
  assign charlieplex_oe = 0;

  ctrl_spi ctrl (
    .clk_i, .rst_ni,

    .spi_sck_i, .spi_csn_i, .spi_data_i, .spi_data_o,
    .debug
  );

//  peri_blinkenlight wb0 (
//    .clk_i, .rst_ni, .wb_c(wbc_p), .wb_p(wbc_p),
//    .blinkenlights(debug)
//  );

  logic peri0_wb_we_o;
  logic [AddrW-1:0] peri0_wb_adr_o;
  logic [DataW-1:0] peri0_wb_dat_o;
  logic peri0_wb_stb_o;
  logic [DataW-1:0] peri0_wb_dat_i;
  logic peri0_wb_ack_i;

  peri_rgb_led peri0 (
    .clk_i, .rst_ni,
    .wb_we_o(peri0_wb_we_o),
    .wb_adr_o(peri0_wb_adr_o),
    .wb_dat_o(peri0_wb_dat_o),
    .wb_stb_o(peri0_wb_stb_o),
    .wb_dat_i(peri0_wb_dat_i),
    .wb_ack_i(peri0_wb_ack_i),
    .rgb(rgb)
  );
  assign peri0_wb_dat_i = ctrl_wb_dat_o;
  assign peri0_wb_adr = ctrl_wb_adr_o[];
  assign peri0_wb_we = wbc_c.we;

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
    AddrW'(0): begin
      wbc_p.dat = wb0_p.dat;
      wbc_p.ack = wb0_p.ack;
      wb0_c.stb = wbc_c.stb;
    end
//    AddrW'(1): begin
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
    rst_ni <= 1;
  end
endmodule
