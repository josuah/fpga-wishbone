`default_nettype none

// Wishbone B4 controller, itself controlled through an SPI peripheral
// the MCU on the other end is the SPI controller, and (via this
// module) the Wishbone controller as well.

module ctrl_uart (
  input logic clk_i,
  input logic rst_ni,
  output iWishbone_Ctrl wb_c,
  input iWishbone_Peri wb_p,
  output logic tx,
  input logic rx
);
  logic rx_stb;
  logic tx_stb;
  logic [7:0] rx_data;
  logic [7:0] tx_data;

  uart_rx mur (
    .clk_i, .rst_ni,
    .stb (rx_stb),
    .data (rx_data),
    .rx
  );

  uart_tx mut (
    .clk_i, .rst_ni,
    .stb (tx_stb),
    .data (tx_data),
    .tx
  );

  ctrl_sync mcs (
    .clk_i, .rst_ni,
    .wb_c, .wb_p,
    .rx_stb, .rx_data,
    .tx_stb, .tx_data
  );

endmodule
