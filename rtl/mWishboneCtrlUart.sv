`default_nettype none
`include "rtl/iWishbone.svh"

// Wishbone B4 controller, itself controlled through an SPI peripheral
// the MCU on the other end is the SPI controller, and (via this
// module) the Wishbone controller as well.

module mWishboneCtrlUart(
  input logic clk,
  input logic rst,
  output  iWishbone_Ctrl wb_c,
  input iWishbone_Peri wb_p,
  output  logic tx,
  input logic rx
);
  logic rx_stb;
  logic tx_stb;
  logic[7:0] rx_data;
  logic[7:0] tx_data;

  mUartRx mur(
    .clk, .rst,
    .stb(rx_stb),
    .data(rx_data),
    .rx
  );

  mUartTx mut(
    .clk, .rst,
    .stb(tx_stb),
    .data(tx_data),
    .tx
  );

  mWishboneCtrlSync mwcs(
    .clk, .rst,
    .wb_c, .wb_p,
    .rx_stb, .rx_data,
    .tx_stb, .tx_data
  );

endmodule
