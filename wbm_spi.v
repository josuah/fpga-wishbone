// Wishbone B4 master, itself controlled through an SPI slave
// the MCU on the other end is the SPI master, and (via this
// module) the Wishbone master as well.

module wbm_spi #(
) (
	// spi slave i/o
	input wire spi_ss,
	input wire spi_sck,
	input wire spi_mosi,
	output wire spi_miso,
);

	// call a single wishbone slave, that is our interconnect

endmodule
