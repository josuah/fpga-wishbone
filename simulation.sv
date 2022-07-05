`default_nettype none

module simulation (
	input logic clk,

	input logic spi_sck,
	input logic spi_csn,
	input logic spi_sdi,
	output logic spi_sdo,
	output logic[6:0] charlieplex_o,
	output logic[6:0] charlieplex_oe,
	output logic[2:0] rgb,
	output logic[7:0] debug
);
	mTop top (
		.clk(clk),
		.spi_sck(spi_sck),
		.spi_csn(spi_csn),
		.spi_sdi(spi_sdi),
		.spi_sdo(spi_sdo),
		.charlieplex_oe(charlieplex_oe),
		.charlieplex_o(charlieplex_o),
		.rgb(rgb),
		.debug(debug)
	);

endmodule
