`default_nettype none

// Wishbone B4 controller, itself controlled through an SPI peripheral
// the MCU on the other end is the SPI controller, and (via this
// module) the Wishbone controller as well.

module ctrl_spi (
  input logic clk_i,
  input logic rst_ni,

  output iWishbone_Ctrl wb_c,
  input iWishbone_Peri wb_p,

  output iSpi_Peri spi_p,
  input iSpi_Ctrl spi_c,
  output logic [7:0] debug
);
  logic rx_stb;
  logic tx_stb;
  logic [7:0] rx_data;
  logic [7:0] tx_data;
  logic unused;

  clock_domain_importer cdc_rx (
    .clk_i,
    .rst_ni,
    .cd_i(rx_cd_i),
    .cd_e(rx_cd_e),
    .data(rx_data),
    .stb(rx_stb)
  );

  clock_domain_exporter cdc_tx (
    .clk_i,
    .rst_ni,
    .cd_e(tx_cd_e),
    .cd_i(tx_cd_i),
    .data(tx_data),
    .stb(tx_stb),
    .ready(unused)
  );

  spi_rx rx (
    .spi_c,
    .cd_i(rx_cd_i),
    .cd_e(rx_cd_e)
  );
  assign debug = rx_data;

  spi_tx tx (
    .spi_c,
    .spi_p,
    .cd_i(tx_cd_i),
    .cd_e(tx_cd_e)
  );

  ctrl_sync ctrl (
    .clk_i,
    .rst_ni,
    .wb_c,
    .wb_p,
    .rx_stb,
    .rx_data,
    .tx_stb,
    .tx_data
  );
endmodule
