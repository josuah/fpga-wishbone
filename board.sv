`default_nettype none

module board (
	// SPI
	output logic gpio_20,
	input logic gpio_10,
	input logic gpio_12,
	input logic gpio_21,

	output logic spi_sck,
	output logic spi_csn,
	output logic spi_sdi,
	output logic spi_sdo,
	output logic[2:0] rgb,
	output logic[6:0] charlieplex,
	output logic[7:0] debug
);
	logic clk;
	logic[6:0] charlieplex_oe;
	logic[6:0] charlieplex_o;
	logic rgb_pwm;
	iSpi.peripheral spi;

	assign spi.sck = spi_sck;
	assign spi.csn = spi_csn;
	assign spi.sdi = spi_sdi;
	assign spi.sdo = spi_sdo;

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
		.RGB0PWM(rgb_pwm[0]),
		.RGB0(rgb[0]),
		.RGB1PWM(rgb_pwm[1]),
		.RGB1(rgb[1]),
		.RGB2PWM(rgb_pwm[2]),
		.RGB2(rgb[2])
	);

	SB_IO #(
		.PIN_TYPE({ 4'b1010, 2'b01 }),
		.PULLUP(0),
		.NEG_TRIGGER(0),
		.IO_STANDARD("SB_LVCMOS")
	) io_charlieplex (
		.PACKAGE_PIN(charlieplex),
		.LATCH_INPUT_VALUE(1'b0),
		.CLOCK_ENABLE(1'b0),
		.OUTPUT_ENABLE(charlieplex_oe),
		.D_OUT_0(charlieplex_o)
	);

	mTop #(
		.TICKS_PER_BAUD(48000000/9600)
	) top (
		.clk,
		.spi, .rgb, .debug,
		.charlieplex_oe(charlieplex_oe),
		.charlieplex_o(charlieplex_o)
	);

endmodule
