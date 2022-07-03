`default_nettype none

module mSimulation #(
	parameter TICKS_PER_BAUD = 4
) (
	// system
	input wire clk,

	// SPI slave I/O
	input wire spi_sck,
	input wire spi_csn,
	input wire spi_sdi,
	output wire spi_sdo,

	// charlie7x5
	output wire [6:0] charlie7x5_o,
	output wire [6:0] charlie7x5_oe,

	// RGB LEDs
	output wire led_r,
	output wire led_g,
	output wire led_b,

	// Debug
	output wire [7:0] debug
);
	wire [6:0] charlie7x5_oe;
	wire [6:0] charlie7x5_o;
	wire [7:0] debug;

	top #(
		.TICKS_PER_BAUD(4)
	) top (
		.clk(clk),
                .spi_sck(spi_sck),
                .spi_csn(spi_csn),
                .spi_sdi(spi_sdi),
                .spi_sdo(spi_sdo),
		.charlie7x5_oe(charlie7x5_oe),
		.charlie7x5_o(charlie7x5_o),
		.led_r(led_r),
		.led_g(led_g),
		.led_b(led_b),
		.debug(debug)
	);

endmodule
