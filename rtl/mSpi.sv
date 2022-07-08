// Wishbone B4 controller, itself controlled through an SPI peripheral
// the MCU on the other end is the SPI controller, and (via this
// module) the Wishbone controller as well.

module mSpi(
	iWishbone.mPeri wb,
	iSpi.mPeri spi,
	output logic[7:0] debug
);
	logic rx_stb, tx_stb;
	logic[7:0] rx_data, tx_data;
	logic unused;

	iClockDomain tx_cdc();
	iClockDomain rx_cdc();

	assign debug = {8{spi.sdi}};

	mClockDomainImport mimp(
		.clk(wb.clk),
		.data(rx_data), .stb(rx_stb),
		.cdc(rx_cdc.mImport)
	);

	mClockDomainExport mexp(
		.clk(wb.clk),
		.data(tx_data), .stb(tx_stb),
		.ready(unused),
		.cdc(tx_cdc.mExport)
	);

	mSpiRx mrx(
		.spi(spi),
		.cdc(rx_cdc.mImport)
	);

	mSpiTx mtx(
		.spi(spi),
		.cdc(tx_cdc.mExport)
	);

	mSpiState mstate(
		.wb,
		.rx_stb(rx_stb), .rx_data(rx_data),
		.tx_stb(tx_stb), .tx_data(tx_data)
	);
endmodule
