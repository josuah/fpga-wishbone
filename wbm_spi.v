// Wishbone B4 master, itself controlled through an SPI slave
// the MCU on the other end is the SPI master, and (via this
// module) the Wishbone master as well.

module wbm_spi #(
) (
	// wishbone b4 pipelined
	input wire wbm_clk_i,
	input wire wbm_rst_i,
	output wire wbm_cyc_o,
	output wire wbm_stb_o,
	output wire wbm_we_o,
	output wire [3:0] wbm_sel_o,
	output wire [31:0] wbm_adr_o,
	output wire [31:0] wbm_dat_o,
	input wire [31:0] wbm_dat_i,
	input wire wbm_stall_i,
	input wire wbm_ack_i,

	// spi slave i/o
	input wire spi_ss,
	input wire spi_sck,
	input wire spi_mosi,
	output wire spi_miso
);

	wire unused = &{
		wbm_clk_i, wbm_rst_i, wbm_dat_i, wbm_stall_i, wbm_ack_i,
		spi_ss, spi_sck, spi_mosi
	};

	assign {
		wbm_stb_o, wbm_cyc_o, wbm_we_o, wbm_sel_o, wbm_adr_o, wbm_dat_o,
		spi_miso
	} = 0;

endmodule
