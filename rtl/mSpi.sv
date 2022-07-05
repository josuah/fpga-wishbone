// Wishbone B4 controller, itself controlled through an SPI peripheral
// the MCU on the other end is the SPI controller, and (via this
// module) the Wishbone controller as well.

module mSpi (
	iWishbone.mPeri wb,
	iSpi.mPeri spi
);
	logic rx_stb, tx_stb;
	logic[7:0] rx_data, tx_data;
	logic unused;

	iClockDomain cdce(spi.sck);
	iClockDomain cdci(wb.clk);

	mClockDomainImport mimp(
		.data(rx_data), .stb(rx_stb),
		.cdc(cdci.mImport)
	);

	mClockDomainExport mexp(
		.data(tx_data), .stb(tx_stb),
		.ready(unused),
		.cdc(cdce.mExport)
	);

	mSpiRx mrx (
		.spi(spi),
		.cdc(cdci.mImport)
	);

	mSpiTx mtx (
		.spi(spi),
		.cdc(cdce.mExport)
	);

	mSpiState mstate (
		.wb,
		.rx_stb(rx_stb), .rx_data(rx_data),
		.tx_stb(tx_stb), .tx_data(tx_data)
	);

endmodule
