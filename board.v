`default_nettype none

module board (
	output wire rgb0,
	output wire rgb1,
	output wire rgb2,
);
	wire clk;
	wire led_r, led_g, led_b;

	// plug the clock
	SB_HFOSC SB_HFOSC (
		.CLKHFPU(1'b1),
		.CLKHFEN(1'b1),
		.CLKHF(clk)
	);

	// plug the led driver
	SB_RGBA_DRV #(
		.RGB0_CURRENT("0b000001"),
		.RGB1_CURRENT("0b000001"),
		.RGB2_CURRENT("0b000001")
	) sb_rgba_drv (
		.RGBLEDEN(1'b1),
		.RGB0PWM(1),
		.RGB1PWM(led_r),
		.RGB2PWM(led_b),
		.CURREN(1'b1),
		.RGB0(rgb0),
		.RGB1(rgb1),
		.RGB2(rgb2)
	);

	// run
	main main (
		.clk(clk),
		.led_r(led_r),
		.led_g(led_g),
		.led_b(led_b)
	);

endmodule
