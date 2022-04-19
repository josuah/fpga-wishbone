`default_nettype none

module wb_uart #(
	parameter TICKS_PER_BAUD = 8
) (
	// Wishbone B4 (5.3)
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire wb_cyc_i,
	input wire wb_stb_i,
	input wire wb_we_i,
	input wire [31:0] wb_dat_i,
	output wire [31:0] wb_dat_o,
	output reg wb_ack_o,
	output wire wb_stall_o,

	// UART
	input wire uart_rx,
	output wire uart_tx
);
	wire [24-1:0] unused = { wb_dat_i[31:8] };

	assign wb_ack_o = wb_cyc_i & wb_stb_i;
	assign wb_dat_o[31:8] = 0;
	assign wb_stall_o = 0;

	wb_uart_rx #(
		.TICKS_PER_BAUD(TICKS_PER_BAUD)
	) rx (
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_dat_o(wb_dat_o[7:0]),
		.uart_rx(uart_rx)
	);

	wb_uart_tx #(
		.TICKS_PER_BAUD(TICKS_PER_BAUD)
	) tx (
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_stb_i(wb_stb_i & wb_we_i),
		.wb_dat_i(wb_dat_i[7:0]),
		.uart_tx(uart_tx)
	);

endmodule
