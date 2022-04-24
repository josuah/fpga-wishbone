`default_nettype none

module simulation #(
	parameter TICKS_PER_BAUD = 4
) (
	input wire clk,

        // Cosimulator
	input wire uart_sampling,
	input wire [7:0] uart_ticks_counter,
	output wire [31:0] uart_ticks_per_baud,

	// status LED
	output wire led,

	// uart I/O
	input wire uart_rx,
	output wire uart_tx
);
	wire unused = &{ uart_sampling, uart_ticks_counter };
	assign uart_ticks_per_baud = TICKS_PER_BAUD;

	top #(
		.TICKS_PER_BAUD(4)
	) top (
		.clk(clk),
		.led(led),
		.uart_tx(uart_tx),
		.uart_rx(uart_rx)
	);
endmodule
