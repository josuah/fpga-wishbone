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

	//iClockDomain cdce(spi.sck);
	logic[7:0] cdce_data;
	logic cdce_req;
	logic cdce_ack;
	//iClockDomain cdci(wb.clk);
	logic[7:0] cdci_data;
	logic cdci_req;
	logic cdci_ack;

	mClockDomainImport mimp(
		.clk(wb.clk),
		.data(rx_data), .stb(rx_stb),
		.cdc_data(cdci_data),
		.cdc_req(cdci_req),
		.cdc_ack(cdci_ack)
	);

	mSpiRx mrx (
		.spi(spi),
		.cdc_data(cdci_data),
		.cdc_req(cdci_req),
		.cdc_ack(cdci_ack)
	);

	mClockDomainExport mexp(
		.clk(wb.clk),
		.data(tx_data), .stb(tx_stb),
		.ready(unused),
		.cdc_data(cdce_data),
		.cdc_req(cdce_req),
		.cdc_ack(cdce_ack)
	);

	mSpiTx mtx (
		.spi(spi),
		.cdc_data(cdce_data),
		.cdc_req(cdce_req),
		.cdc_ack(cdce_ack)
	);

	mSpiState mstate (
		.wb,
		.rx_stb(rx_stb), .rx_data(rx_data),
		.tx_stb(tx_stb), .tx_data(tx_data)
	);

endmodule
