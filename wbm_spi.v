// Wishbone B4 master, itself controlled through an SPI slave
// the MCU on the other end is the SPI master, and (via this
// module) the Wishbone master as well.

module wbm_spi #(
) (
	// Wishbone B4 pipelined
	input wire wbm_clk_i,
	input wire wbm_rst_i,
	output wire wbm_cyc_o,
	output wire wbm_stb_o,
	output wire wbm_we_o,
	output wire [3:0] wbm_sel_o,
	output wire [7:0] wbm_adr_o,
	output wire [31:0] wbm_dat_o,
	input wire [31:0] wbm_dat_i,
	input wire wbm_stall_i,
	input wire wbm_ack_i,

	// SPI slave I/O
	input wire spi_sck,
	input wire spi_csn,
	input wire spi_sdi,
	output wire spi_sdo
);
	wire rx_handshake_wb, rx_handshake_spi;
	wire tx_handshake_wb, tx_handshake_spi;
	wire [7:0] rx_handshake_data;
	wire [7:0] tx_handshake_data;

	wbm_spi_rx rx (
		.spi_sck(spi_sck),
		.spi_csn(spi_csn),
		.spi_sdi(spi_sdi),
		.spi_sdo(spi_sdo),
		.handshake_wb(rx_handshake_wb),
		.handshake_spi(rx_handshake_spi),
		.handshake_data(rx_handshake_data)
	);

	wbm_spi_tx tx (
		.spi_sck(spi_sck),
		.spi_csn(spi_csn),
		.spi_sdi(spi_sdi),
		.spi_sdo(spi_sdo),
		.handshake_wb(tx_handshake_wb),
		.handshake_spi(tx_handshake_spi),
		.handshake_data(tx_handshake_data)
	);

endmodule

// la la la la not listenning and only saying la la la la
