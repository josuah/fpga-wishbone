`default_nettype none

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
	iWishbone.controller iw,
	iSpi.peripheral is
);
	wire [7:0] rx_handshake_data, tx_data;
	wire [7:0] tx_handshake_data, rx_data;
	wire rx_handshake_req, rx_handshake_ack, rx_stb;
	wire tx_handshake_req, tx_handshake_ack, tx_stb, tx_ready;
	wire unused = |{ tx_ready };

	iClockDomainCrossing.import

	clock_domain_export #(
		.SIZE(8)
	) export (
		.clk(iw.clk),
		.data(tx_data),
		.stb(tx_stb),
		.ready(tx_ready),
		.handshake_req(tx_handshake_req),
		.handshake_ack(tx_handshake_ack),
		.handshake_data(tx_handshake_data)
	);

	wbm_spi_tx tx (
		.spi_sck(spi_sck),
		.spi_csn(spi_csn),
		.spi_sdo(spi_sdo),
		.handshake_req(tx_handshake_req),
		.handshake_ack(tx_handshake_ack),
		.handshake_data(tx_handshake_data)
	);

	mClockDomainImport #(
		.SIZE(8)
	) import (
		.clk(iw.clk),
		.data(rx_data),
		.stb(rx_stb),
		.icdc(cdci),
		.handshake_ack(rx_handshake_ack),
		.handshake_data(rx_handshake_data)
	);

	mClockDomainImport rx (
		.spi_sck(spi_sck),
		.spi_csn(spi_csn),
		.spi_sdi(spi_sdi),
		.handshake_req(rx_handshake_req),
		.handshake_ack(rx_handshake_ack),
		.handshake_data(rx_handshake_data)
	);

	wbm_spi_state state (
		.iw(iw),
		.rx_stb(rx_stb),
		.rx_data(rx_data),
		.tx_stb(tx_stb),
		.tx_data(tx_data)
	);

endmodule
