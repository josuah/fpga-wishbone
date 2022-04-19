module board (
	output wire rgb0,
	output wire rgb1,
	output wire rgb2,
);
	wire clk;
	wire led_r, led_g, led_b;

	// internal oscillator
	SB_HFOSC SB_HFOSC (
		.CLKHFPU(1'b1),
		.CLKHFEN(1'b1),
		.CLKHF(clk)
	);

	// RGB primitive with control of the current
	SB_RGBA_DRV #(
		.RGB0_CURRENT("0b000001"),
		.RGB1_CURRENT("0b000001"),
		.RGB2_CURRENT("0b000001")
	) sb_rgba_drv (
		.RGBLEDEN(1'b1),
		.RGB0PWM(led_g),
		.RGB1PWM(led_b),
		.RGB2PWM(led_r),
		.CURREN(1'b1),
		.RGB0(rgb0),
		.RGB1(rgb1),
		.RGB2(rgb2)
	);

	top top (
		.clk(clk),
		.led_r(led_r),
		.led_g(led_g),
		.led_b(led_b)
	);

endmodule
