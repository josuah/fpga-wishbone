`default_nettype none

// Wishbone B4 controller, itself controlled through an UART interface
// with an MCU on the other end.

module ctrl_uart (
  input clk_i,
  input rst_ni,

  // wishbone b4 controller
  output wb_we_o,
  output wb_adr_o,
  output wb_dat_o,
  output wb_stb_o,
  input wb_dat_i,
  input wb_ack_i,

  // uart i/o
  output uart_o,
  input uart_i
);
  logic rx_valid;
  logic [7:0] rx_data;

  uart_rx rx (
    .clk_i, .rst_ni,
    .valid_o(rx_valid), .data_o(rx_data),
    .uart_i
  );

  logic tx_valid;
  logic [7:0] tx_data;

  uart_tx tx (
    .clk_i, .rst_ni,
    .valid_i(tx_valid), .data_i(tx_data),
    .uart_o
  );

  ctrl_sync ctrl (
    .clk_i, .rst_ni,
    .wb_we_o, .wb_adr_o, .wb_dat_o, .wb_stb_o, .wb_dat_i, .wb_ack_i,
    .valid_i(rx_valid), .data_i(rx_data),
    .valid_o(tx_valid), .data_o(tx_data)
  );

endmodule
