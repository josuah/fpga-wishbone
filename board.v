module board (
	// SPI
	output wire gpio_20,
	input wire gpio_10,
	input wire gpio_12,
	input wire gpio_21,

	// RGB LED
	output wire rgb0,	// red
	output wire rgb1,	// green
	output wire rgb2,	// blue

	// charlie7x5
	output wire gpio_38,
	output wire gpio_36,
	output wire gpio_34,
	output wire gpio_31,
	output wire gpio_32,
	output wire gpio_26,
	output wire gpio_23,

	// Debug
	output wire gpio_2,
	output wire gpio_46,
	output wire gpio_47,
	output wire gpio_45,
	output wire gpio_48,
	output wire gpio_3,
	output wire gpio_4,
	output wire gpio_44
);
	wire [6:0] charlie7x5_oe;
	wire [6:0] charlie7x5_o;
	wire led_r, led_g, led_b;

	assign gpio_36 = clk;

	SB_HFOSC SB_HFOSC (
		.CLKHFPU(1'b1),
		.CLKHFEN(1'b1),
		.CLKHF(clk)
	);

	SB_RGBA_DRV #(
		.CURRENT_MODE("0b1"),		/* half current */
		.RGB0_CURRENT("0b000011"), 	/* 4 mA */
		.RGB1_CURRENT("0b000011"),	/* 4 mA */
		.RGB2_CURRENT("0b000011")	/* 4 mA */
	) RGBA_DRIVER (
		.CURREN(1'b1),
		.RGBLEDEN(1'b1),
		.RGB0PWM(led_g),
		.RGB0(rgb0),
		.RGB1PWM(led_r),
		.RGB1(rgb1),
		.RGB2PWM(led_b),
		.RGB2(rgb2)
	);

	SB_IO #(
		.PIN_TYPE({ 4'b1010, 2'b01 }),
		.PULLUP(0),
		.NEG_TRIGGER(0),
		.IO_STANDARD("SB_LVCMOS")
	) SB_IO_charlie7x5 (
		.PACKAGE_PIN({ gpio_38, gpio_36, gpio_34, gpio_31, gpio_32,
				gpio_26, gpio_23 }),
		.LATCH_INPUT_VALUE(1'b0),
		.CLOCK_ENABLE(1'b0),
		.OUTPUT_ENABLE(charlie7x5_oe),
		.D_OUT_0(charlie7x5_o)
	);

	top #(
		.TICKS_PER_BAUD(48000000/9600)
	) top (
		.clk(clk),
		.charlie7x5_oe(charlie7x5_oe),
		.charlie7x5_o(charlie7x5_o),
		.spi_sck(gpio_12),
		.spi_csn(gpio_10),
		.spi_sdi(gpio_21),
		.spi_sdo(gpio_20),
		.led_r(led_r),
		.led_g(led_g),
		.led_b(led_b),
		.debug({ gpio_2, gpio_46, gpio_47, gpio_45, gpio_48, gpio_3,
				gpio_4, gpio_44 })
	);

endmodule
