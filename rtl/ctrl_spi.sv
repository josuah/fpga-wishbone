`default_nettype none
//
// Wishbone B4 controller, itself controlled through an SPI peripheral
// the MCU on the other end is the SPI controller, and (via this
// module) the Wishbone controller as well.
//
module ctrl_spi (
  input  clk_i,
  input  rst_ni,

  // wishbone b4 controller
  output wb_we_o,
  output wb_stb_o,
  input  wb_ack_i,
  output [3:0] wb_adr_o,
  output [7:0] wb_dat_o,
  input  [7:0] wb_dat_i,

  // spi peripheral
  input  spi_sck_i,
  input  spi_csn_i,
  input  spi_sd_i,
  output spi_sd_o
);
  logic [7:0] rx_data;
  logic rx_req;

  spi_rx rx (
    .clk_sys_i(clk_i), .clk_spi_i(spi_sck_i),
    .spi_csn_i, .spi_sd_i,
    .rx_req_o(rx_req), .rx_data_o(rx_data)
  );

  logic [7:0] tx_data;
  logic tx_req;

  spi_tx tx (
    .clk_sys_i(clk_i), .clk_spi_i(spi_sck_i),
    .spi_csn_i, .spi_sd_o,
    .tx_req_i(tx_req), .tx_data_i(tx_data)
  );

  ctrl_sync ctrl (
    .clk_i, .rst_ni,
    .wb_dat_i, .wb_ack_i, .wb_we_o, .wb_adr_o, .wb_dat_o, .wb_stb_o,
    .rx_req_i(rx_req), .rx_data_i(rx_data),
    .tx_req_o(tx_req), .tx_data_o(tx_data)
  );

endmodule
