`default_nettype none

module simulation #(
	parameter TICKS_PER_BAUD = 4
) (
	// system
	input wire clk,

	// SPI slave I/O
	input wire spi_sck,
	input wire spi_csn,
	input wire spi_sdi,
	output wire spi_sdo

/*
	// charlie7x5
	output wire [6:0] charlie7x5_o,
	output wire [6:0] charlie7x5_oe
*/
);
/*
	wire [6:0] charlie7x5_oe;
	wire [6:0] charlie7x5_o;
*/
	wire unused = &{ /*charlie7x5_o , charlie7x5_oe,*/ dummy };
	wire [7:0] dummy;

	// top //

	top #(
		.TICKS_PER_BAUD(4)
	) top (
		.clk(clk),
                .spi_sck(spi_sck),
                .spi_csn(spi_csn),
                .spi_sdi(spi_sdi),
                .spi_sdo(spi_sdo),
/*
		.charlie7x5_oe(charlie7x5_oe),
		.charlie7x5_o(charlie7x5_o),
*/
		.debug(dummy)
	);

endmodule
