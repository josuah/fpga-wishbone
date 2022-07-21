`default_nettype none

// Wishbone B4 controller, itself controlled through an SPI peripheral
// the MCU on the other end is the SPI controller, and (via this
// module) the Wishbone controller as well.

module ctrl_spi (
  input clk_i,
  input rst_ni,

  // wishbone b4 controller
  input wb_dat_i,
  input wb_ack_i,
  output wb_we_o,
  output wb_adr_o,
  output wb_dat_o,
  output wb_stb_o,

  // spi peripheral
  input spi_sck,
  input spi_csn,
  input spi_sdi,
  output spi_sdo
);
  logic unused;

  logic [7:0] rx_data;
  logic rx_valid;

  spi_rx rx (
    .spi_sck, .spi_csn, .spi_sdi, .spi_sdo,
    .valid_o(rx_valid),
    .data_o(rx_data)
  );

  logic [7:0] tx_data;
  logic tx_valid;

  spi_tx tx (
    .spi_sck, .spi_csn, .spi_sdi, .spi_sdo,
    .ready_o(unused),
    .valid_i(tx_valid),
    .data_i(tx_data)
  );

  ctrl_sync ctrl (
    .clk_i, .rst_ni,
    .wb_dat_i, .wb_ack_i, .wb_we_o, .wb_adr_o, .wb_dat_o, .wb_stb_o,
    .valid_i(rx_valid),
    .data_i(rx_data),
    .valid_o(tx_valid),
    .data_o(tx_data)
  );

endmodule
