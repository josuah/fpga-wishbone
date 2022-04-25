`default_nettype none

module simulation #(
	parameter TICKS_PER_BAUD = 4
) (
	input wire clock,

        // Cosimulator
	input wire uart_sampling,
	input wire [7:0] uart_ticks_counter,
	output wire [31:0] uart_ticks_per_baud,

	// uart I/O
	input wire uart_rx,
	output wire uart_tx,

	// LED output
	output wire led_r,
	output wire led_g,
	output wire led_b,

	// PWM output
	output wire pwm_servo
);
	wire unused = &{ uart_sampling, uart_ticks_counter };
	assign uart_ticks_per_baud = TICKS_PER_BAUD;

	top #(
		.TICKS_PER_BAUD(4)
	) top (
		.clock(clock),
		.uart_tx(uart_tx),
		.uart_rx(uart_rx),
		.led_r(led_r),
		.led_g(led_g),
		.led_b(led_b),
		.pwm_servo(pwm_servo)
	);
endmodule
