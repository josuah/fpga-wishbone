module board (
	// charlie7x5
	output wire gpio_2,
	output wire gpio_47,
	output wire gpio_48,
	output wire gpio_4,
	output wire gpio_6,
	output wire gpio_11,
	output wire gpio_19,
);
	wire clk;

	wire [6:0] charlie7x5_oe;
	wire [6:0] charlie7x5_o;

	// internal oscillator //

	SB_HFOSC SB_HFOSC (
		.CLKHFPU(1'b1),
		.CLKHFEN(1'b1),
		.CLKHF(clk)
	);

	// i/o cell //

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

	// top //

	top #(
		.TICKS_PER_BAUD(48000000/9600)
	) top (
		.clk(clk),
		.charlie7x5_oe(charlie7x5_oe),
		.charlie7x5_o(charlie7x5_o)
	);

endmodule
