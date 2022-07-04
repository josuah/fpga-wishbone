
// Wishbone B4 controller, itself controlled through an SPI peripheral
// the MCU on the other end is the SPI controller, and (via this
// module) the Wishbone controller as well.
//
// Wishbone read:
//
//	W000SSSS AAAAAAAA :::::::: :::::::: :::::::: :::::::: :::::::: ::::::::
//	│   ├──┘ ├──────┘
//	│:::│::: │::::::: 00000000 11111111 DDDDDDDD DDDDDDDD DDDDDDDD DDDDDDDD
//	│   │    │        ├──────┘ ├──────┘ ├─────────────────────────────────┘
//	WE  SEL  ADR      STALL    ACK      DAT
//
// Wishbone write:
//
//	W000SSSS AAAAAAAA DDDDDDDD DDDDDDDD DDDDDDDD DDDDDDDD :::::::: ::::::::
//	│   ├──┘ ├──────┘ ├─────────────────────────────────┘
//	│:::│::: │::::::: │::::::: :::::::: :::::::: :::::::: 00000000 11111111
//	│   │    │        │                                   ├──────┘ ├──────┘
//	WE  SEL  ADR      DAT                                 STALL    ACK
//

module mSpi (
	iWishbone.controller wb,
	iSpi.peripheral spi
);
	logic [7:0] rx_handshake_data, tx_data;
	logic [7:0] tx_handshake_data, rx_data;
	logic rx_handshake_req, rx_handshake_ack, rx_stb;
	logic tx_handshake_req, tx_handshake_ack, tx_stb, tx_ready;
	logic unused = |{ tx_ready };

	iClockDomainCrossing.importer cdci;
	iClockDomainCrossing.exporter cdce;

	mClockDomainExporter #( .SIZE(8) ) exporter (
		.clk(wb.clk), .data(tx_data), .stb(tx_stb),
		.cdc(cdce)
	);

	mSpiTx mtx (
		.spi(spi),
		.cdc(cdci)
	);

	mClockDomainImporter #( .SIZE(8) ) importer (
		.clk(wb.clk), .data(rx_data), .stb(rx_stb),
		.cdc(cdci)
	);

	mSpiRx mrx (
		.spi,
		.cdc(cdce)
	);

	mSpiState state (
		.wb,
		.rx_stb(rx_stb), .rx_data(rx_data),
		.tx_stb(tx_stb), .tx_data(tx_data)
	);

endmodule
