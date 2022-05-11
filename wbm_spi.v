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
	wire unused = &{
		wbm_clk_i, wbm_rst_i, wbm_dat_i, wbm_stall_i, wbm_ack_i,
		spi_sck, spi_csn, spi_sdi, rx_data
	};

	assign {
		wbm_cyc_o, wbm_stb_o, wbm_we_o, wbm_sel_o, wbm_adr_o, wbm_dat_o,
		rx_ack, tx_ack, tx_data
	} = 1;


	// clock domain crossing //

	wire rx_handshake_wb, rx_handshake_spi, rx_ack;
	wire tx_handshake_wb, tx_handshake_spi, tx_ack;
	wire [7:0] rx_handshake_buffer, rx_data;
	wire [7:0] tx_handshake_buffer, tx_data;

	clock_domain_export clock_domain_export (
		.clk(wbm_clk_i),
		.handshake_other(tx_handshake_spi),
		.handshake_local(tx_handshake_wb),
		.handshake_buffer(tx_handshake_buffer),
		.data(tx_data),
		.ack(tx_ack)
	);

	clock_domain_import clock_domain_import (
		.clk(wbm_clk_i),
		.handshake_other(rx_handshake_spi),
		.handshake_local(rx_handshake_wb),
		.handshake_buffer(rx_handshake_buffer),
		.data(rx_data),
		.ack(rx_ack)
	);



	// tx/rx logics //

	wbm_spi_rx rx (
		.spi_sck(spi_sck),
		.spi_csn(spi_csn),
		.spi_sdi(spi_sdi),
		.handshake_wb(rx_handshake_wb),
		.handshake_spi(rx_handshake_spi),
		.handshake_buffer(rx_handshake_buffer)
	);

	wbm_spi_tx tx (
		.spi_sck(spi_sck),
		.spi_csn(spi_csn),
		.spi_sdo(spi_sdo),
		.handshake_wb(tx_handshake_wb),
		.handshake_spi(tx_handshake_spi),
		.handshake_buffer(tx_handshake_buffer)
	);

	always @(posedge wbm_clk_i) begin
		
	end

endmodule

// la la la la not listenning and only saying la la la la
