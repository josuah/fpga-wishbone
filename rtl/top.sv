`default_nettype none

module top #(
  parameter int AddrW = 4,
  parameter int DataW = 8
) (
  input clk_i,

  // spi peripheral
  input spi_sck_i,
  input spi_csn_i,
  input spi_sd_i,
  output spi_sd_o,

  // led gpio
  output led_r_o,
  output led_g_o,
  output led_b_o,
  output [7:0] debug_o,

  // charlieplexed gpio
  output [6:0] charlieplex_o,
  output [6:0] charlieplex_en_o
);
  // generate the reset signal
  logic rst_ni;
  initial rst_ni = 0;
  always_ff @(posedge clk_i) begin
    rst_ni <= 1;
  end

  logic ctrl_wb_we, ctrl_wb_stb, ctrl_wb_ack;
  logic [AddrW-1:0] ctrl_wb_adr;
  logic [DataW-1:0] ctrl_wb_dat_i, ctrl_wb_dat_o;

  assign charlieplex_o = 0;
  assign charlieplex_en_o = 0;
  assign debug_o = 0;

  ctrl_spi ctrl (
    .clk_i, .rst_ni,
    .wb_we_o(ctrl_wb_we),
    .wb_adr_o(ctrl_wb_adr),
    .wb_dat_o(ctrl_wb_dat_o),
    .wb_stb_o(ctrl_wb_stb),
    .wb_dat_i(ctrl_wb_dat_i),
    .wb_ack_i(ctrl_wb_ack),
    .spi_sck_i, .spi_csn_i, .spi_sd_i, .spi_sd_o
  );

//  peri_blinkenlight peri0 (
//    .clk_i, .rst_ni, .wb_c(wbc_p), .wb_p(wbc_p),
//    .blinkenlights(debug)
//  );

  logic peri0_wb_we, peri0_wb_stb, peri0_wb_ack;
  logic [AddrW-1:0] peri0_wb_adr;
  logic [DataW-1:0] peri0_wb_dat_i, peri0_wb_dat_o;
  peri_rgb_led peri0 (
    .clk_i, .rst_ni,
    .wb_we_i(peri0_wb_we),
    .wb_adr_i(peri0_wb_adr),
    .wb_dat_i(peri0_wb_dat_i),
    .wb_stb_i(peri0_wb_stb),
    .wb_dat_o(peri0_wb_dat_o),
    .wb_ack_o(peri0_wb_ack),
    .led_r_o, .led_g_o, .led_b_o
  );
  assign peri0_wb_dat_i = ctrl_wb_dat_o;
  assign peri0_wb_adr = ctrl_wb_adr[3:0];
  assign peri0_wb_we = ctrl_wb_we;

//  logic peri1_wb_we, peri1_wb_stb, peri1_wb_ack;
//  logic [AddrW-1:0] peri1_wb_adr;
//  logic [DataW-1:0] peri1_wb_dat_i, peri1_wb_dat_o;
//  peri_debug peri1 (
//    .clk_i, .rst_ni, .wb_p(wb1_p), .wb_c(wb1_c),
//    .debug(debug)
//  );
//  assign peri1_wb_dat = ctrl_wb_dat_o;
//  assign peri1_wb_adr = ctrl_wb_adr;
//  assign peri1_wb_we = ctrl_wb_we;
//  assign wb0_c[13] = 1'b1;

//  logic peri2_wb_we, peri2_wb_stb, peri2_wb_ack;
//  logic [AddrW-1:0] peri2_wb_adr;
//  logic [DataW-1:0] peri2_wb_dat_i, peri2_wb_dat_o;
//  peri_charlieplex peri2 (
//    .clk_i, .rst_ni, .wb_p(wb2_p), .wb_p(wb2_c),
//    .charlieplex_o, .charlieplex_en_o
//  );
//  assign peri2_wb_dat = ctrl_wb_dat_o;
//  assign peri2_wb_adr = ctrl_wb_adr;
//  assign peri2_wb_we = ctrl_wb_we;

  always_comb begin
    case (ctrl_wb_adr)
    AddrW'(0): begin
      ctrl_wb_dat_i = peri0_wb_dat_o;
      ctrl_wb_ack = peri0_wb_ack;
      peri0_wb_stb = ctrl_wb_stb;
    end
//    AddrW'(1): begin
//      ctrl_wb_dat_i = peri1_wb_dat_o;
//      ctrl_wb_ack = peri1_wb_ack;
//      peri1_wb_stb = ctrl_wb_stb;
//    end
    default: begin
      ctrl_wb_dat_i = 8'b00000000;
      ctrl_wb_ack = 1'b0;
      peri0_wb_stb = 0;
//      peri1_wb_stb = 0;
    end
    endcase
  end

endmodule
