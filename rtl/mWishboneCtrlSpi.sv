`default_nettype none
`include "rtl/iSpi.svh"
`include "rtl/iClockDomain.svh"
`include "rtl/iWishbone.svh"

// Wishbone B4 controller, itself controlled through an SPI peripheral
// the MCU on the other end is the SPI controller, and (via this
// module) the Wishbone controller as well.

module mWishboneCtrlSpi(
	input	logic clk,
	input	logic rst,
	output	iWishbone_Ctrl wb_c,
	input	iWishbone_Peri wb_p,
	output	iSpi_Peri spi_p,
	input	iSpi_Ctrl spi_c,
	output	logic[7:0] debug
);
	logic rx_stb;
	logic tx_stb;
	logic[7:0] rx_data;
	logic[7:0] tx_data;
	logic unused;

	iClockDomain_Imp tx_cd_i;
	iClockDomain_Exp tx_cd_e;

	iClockDomain_Imp rx_cd_i;
	iClockDomain_Exp rx_cd_e;

	mClockDomainImporter mcdi(
		.clk, .rst,
		.cd_i(rx_cd_i), .cd_e(rx_cd_e),
		.data(rx_data),
		.stb(rx_stb)
	);

	mClockDomainExporter mcde(
		.clk, .rst,
		.cd_e(tx_cd_e), .cd_i(tx_cd_i),
		.data(tx_data),
		.stb(tx_stb),
		.ready(unused)
	);

	mSpiRx msr(
		.spi_c,
		.cd_i(rx_cd_i), .cd_e(rx_cd_e)
	);
	assign debug = rx_data;

	mSpiTx mst(
		.spi_c, .spi_p,
		.cd_i(tx_cd_i), .cd_e(tx_cd_e)
	);

	mWishboneCtrlSync mwcs(
		.clk, .rst,
		.wb_c, .wb_p,
		.rx_stb, .rx_data,
		.tx_stb, .tx_data
	);
endmodule
