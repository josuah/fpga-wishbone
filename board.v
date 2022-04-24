module board (
	output wire rgb0,
	output wire rgb1,
	output wire rgb2,
	output wire gpio_23,
	output wire gpio_25
);
	wire clk;
	wire led_r;

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
		.RGB0PWM(0),
		.RGB1PWM(0),
		.RGB2PWM(led_r),
		.CURREN(1'b1),
		.RGB0(rgb0),
		.RGB1(rgb1),
		.RGB2(rgb2)
	);

	top #(
		.TICKS_PER_BAUD(4)
	) top (
		.clk(clk),
		.led(led_r),
		.uart_tx(gpio_23),
		.uart_rx(gpio_25)
	);

endmodule
