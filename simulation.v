`default_nettype none

module simulation (
	input wire clk,

	// PWM-controlled LEDs
	output wire led_r,
	output wire led_g,
	output wire led_b
);
	top top (
		.clk(clk),
		.led_r(led_r),
		.led_g(led_g),
		.led_b(led_b)
	);
endmodule
