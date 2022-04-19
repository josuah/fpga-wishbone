`default_nettype none

module simulation #(
	parameter TICKS_PER_BAUD = 3
) (
	// Cosimulator
	output wire [31:0] o_uart_setup,
	input wire i_uart_sampling,
	input wire [7:0] i_uart_ticks_cnt,

	// Wishbone B4
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire wb_stb_i,
	input wire wb_cyc_i,
	input wire wb_we_i,
	input wire [31:0] wb_dat_i,
	output wire [31:0] wb_dat_o,
	output wire wb_stall_o,
	output wire wb_ack_o
);
	wire [8:0] unused = { i_uart_sampling, i_uart_ticks_cnt };
	wire uart_loop;

	wb_pwm #(
		.CHANNELS(CHANNELS)
	) wb_pwm (
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_stb_i(wb_stb_i),
		.wb_cyc_i(wb_cyc_i),
		.wb_we_i(wb_we_i),
		.wb_dat_i(wb_dat_i),
		.wb_dat_o(wb_dat_o),
		.wb_stall_o(wb_stall_o),
		.wb_ack_o(wb_ack_o),
		/* loop input back to output */
		.uart_rx(uart_loop),
		.uart_tx(uart_loop)
	);

	assign o_uart_setup = TICKS_PER_BAUD;
endmodule
