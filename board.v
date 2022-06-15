module board (
/*
	// charlie7x5
	output wire gpio_2,
	output wire gpio_47,
	output wire gpio_48,
	output wire gpio_4,
	output wire gpio_6,
	output wire gpio_11,
	output wire gpio_19,
*/

	// SPI
	output wire gpio_34,
	input wire gpio_37,
	input wire gpio_31,
	input wire gpio_35,

	// debug
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
	wire unused = |{ charlie7x5_oe, charlie7x5_o };

	assign gpio_36 = clk;

	SB_HFOSC SB_HFOSC (
		.CLKHFPU(1'b1),
		.CLKHFEN(1'b1),
		.CLKHF(clk)
	);

/*
	SB_IO #(
		.PIN_TYPE({ 4'b1010, 2'b01 }),
		.PULLUP(0),
		.NEG_TRIGGER(0),
		.IO_STANDARD("SB_LVCMOS")
	) SB_IO [6:0] (
		.PACKAGE_PIN({
			gpio_2, gpio_47, gpio_48, gpio_4, gpio_6, gpio_11,
			gpio_19
		}),
		.LATCH_INPUT_VALUE(1'b0),
		.CLOCK_ENABLE(1'b0),
		.OUTPUT_ENABLE(charlie7x5_oe),
		.D_OUT_0(charlie7x5_o)
	);
*/

	top #(
		.TICKS_PER_BAUD(48000000/9600)
	) top (
		.clk(clk),
		.charlie7x5_oe(charlie7x5_oe),
		.charlie7x5_o(charlie7x5_o),
		.spi_sck(gpio_31),
		.spi_csn(gpio_37),
		.spi_sdi(gpio_35),
		.spi_sdo(gpio_34),
		.debug({
			gpio_2, gpio_46, gpio_47, gpio_45, gpio_48, gpio_3, gpio_4, gpio_44
		})
	);

endmodule
