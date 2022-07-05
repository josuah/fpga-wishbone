`default_nettype none

module board (
	output logic gpio_spi_sck,
	output logic gpio_spi_csn,
	output logic gpio_spi_sdi,
	output logic gpio_spi_sdo,
	output logic[2:0] gpio_rgb,
	output logic[6:0] gpio_charlieplex,
	output logic[7:0] gpio_debug
);
	logic clk;
	logic[6:0] charlieplex_oe;
	logic[6:0] charlieplex_o;
	logic[2:0] rgb;

	SB_HFOSC hfosc (
		.CLKHFPU(1'b1),
		.CLKHFEN(1'b1),
		.CLKHF(clk)
	);

	SB_RGBA_DRV #(
		.CURRENT_MODE("0b1"),		/* half current */
		.RGB0_CURRENT("0b000011"), 	/* 4 mA */
		.RGB1_CURRENT("0b000011"),	/* 4 mA */
		.RGB2_CURRENT("0b000011")	/* 4 mA */
	) rgba_drv (
		.CURREN(1'b1),
		.RGBLEDEN(1'b1),
		.RGB0PWM(rgb[0]),
		.RGB0(gpio_rgb[0]),
		.RGB1PWM(rgb[1]),
		.RGB1(gpio_rgb[1]),
		.RGB2PWM(rgb[2]),
		.RGB2(gpio_rgb[2])
	);

	SB_IO #(
		.PIN_TYPE({ 4'b1010, 2'b01 }),
		.PULLUP(0),
		.NEG_TRIGGER(0),
		.IO_STANDARD("SB_LVCMOS")
	) io_charlieplex (
		.PACKAGE_PIN(gpio_charlieplex),
		.LATCH_INPUT_VALUE(1'b0),
		.CLOCK_ENABLE(1'b0),
		.OUTPUT_ENABLE(charlieplex_oe),
		.D_OUT_0(charlieplex_o)
	);

	mTop top (
		.clk,
		.spi_sck(gpio_spi_sck),
		.spi_csn(gpio_spi_csn),
		.spi_sdi(gpio_spi_sdi),
		.spi_sdo(gpio_spi_sdo),
		.rgb(rgb),
		.debug(gpio_debug),
		.charlieplex_oe(charlieplex_oe),
		.charlieplex_o(charlieplex_o)
	);

endmodule
