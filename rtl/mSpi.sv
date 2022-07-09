// Wishbone B4 controller, itself controlled through an SPI peripheral
// the MCU on the other end is the SPI controller, and (via this
// module) the Wishbone controller as well.

module mSpi(
	input	logic clk,
	input	logic rst,
	output	iWishbone_Ctrl wb_c,
	input	iWishbone_Peri wb_p,
	output	iSpi_Peri spi_p,
	input	iSpi_Ctrl spi_c,
	output	logic[7:0] debug
);
	logic rx_stb, tx_stb;
	logic[7:0] rx_data, tx_data;
	logic unused;

	iClockDomain_Imp tx_cd_i;
	iClockDomain_Exp tx_cd_e;

	iClockDomain_Imp rx_cd_i;
	iClockDomain_Exp rx_cd_e;

	assign debug = {8{spi.sdi}};

	mClockDomainImporter mcdi(
		.clk, .rst,
		.data(rx_data),
		.stb(rx_stb),
		.cd_i(rx_cd_i),
		.cd_e(rx_cd_e)
	);

	mClockDomainExporter mcde(
		.clk, .rst,
		.data(tx_data),
		.stb(tx_stb),
		.ready(unused),
		.cd_e(tx_cd_e),
		.cd_i(tx_cd_i)
	);

	mSpiRx msr(
		.spi_c, .spi_p,
		.cd_i(rx_cd_i),
		.cd_e(rx_cd_e)
	);

	mSpiTx mst(
		.spi_c, .spi_p,
		.cd_i(tx_cd_i),
		.cd_e(tx_cd_e)
	);

	mSpiState mss(
		.clk, .rst,
		.wb_p, .wb_c,
		.rx_stb(rx_stb),
		.rx_data(rx_data),
		.tx_stb(tx_stb),
		.tx_data(tx_data)
	);
endmodule
