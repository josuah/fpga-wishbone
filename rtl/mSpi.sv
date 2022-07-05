// Wishbone B4 controller, itself controlled through an SPI peripheral
// the MCU on the other end is the SPI controller, and (via this
// module) the Wishbone controller as well.

module mSpi (
	iWishbone.mPeri wb,
	iSpi.mPeri spi
);
	logic rx_stb, tx_stb;
	logic[7:0] rx_data, tx_data;

	iClockDomainCrossing cdce();

	mClockDomainExporter #( .pBits(8) ) exporter (
		.clk(wb.clk), .data(tx_data), .stb(tx_stb),
		.cdc(cdce.mExport)
	);

	mSpiRx mrx (
		.spi(spi),
		.cdc(cdce.mExport)
	);

	iClockDomainCrossing cdci();

	mClockDomainImporter #( .pBits(8) ) importer (
		.clk(wb.clk), .data(rx_data), .stb(rx_stb),
		.cdc(cdci.mImport)
	);

	mSpiTx mtx (
		.spi(spi),
		.cdc(cdci.mImport)
	);

	mSpiState mstate (
		.wb,
		.rx_stb(rx_stb), .rx_data(rx_data),
		.tx_stb(tx_stb), .tx_data(tx_data)
	);

endmodule
