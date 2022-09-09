`default_nettype none

// Wishbone B4 controller, itself controlled through an UART interface
// with an MCU on the other end.

module ctrl_uart (
  input clk_i,
  input rst_ni,

  // wishbone b4 controller
  output wb_we_o,
  output wb_stb_o,
  input wb_ack_i,
  output [3:0] wb_adr_o,
  output [7:0] wb_dat_o,
  input [7:0] wb_dat_i,

  // uart i/o
  output uart_tx_no,
  input uart_rx_ni
);
  logic rx_stb;
  logic [7:0] rx_data;

  uart_rx rx (
    .clk_i, .rst_ni,
    .rx_stb_o(rx_stb), .rx_data_o(rx_data),
    .uart_rx_ni
  );

  logic tx_stb;
  logic [7:0] tx_data;

  uart_tx tx (
    .clk_i, .rst_ni,
    .tx_stb_i(tx_stb), .tx_data_i(tx_data),
    .uart_tx_no
  );

  ctrl_async ctrl (
    .clk_i, .rst_ni,
    .wb_we_o, .wb_adr_o, .wb_dat_o, .wb_stb_o, .wb_dat_i, .wb_ack_i,
    .rx_stb_i(rx_stb), .rx_data_i(rx_data),
    .tx_stb_o(tx_stb), .tx_data_o(tx_data)
  );

endmodule
