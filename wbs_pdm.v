`default_nettype none

// Pulse Density Modulation module

// CHANNEL_NUM:
//	Number of PDM outputs provided through `pdm`. Affects the addresses
//	at which it is possible to write duty-cycle length data.
//
// Wishbone address 0x0 to CHANNEL_NUM-1:
//      One address per channel for setting the level.
//	wb_dat_o set at ((1 << BIT_RESOLUTION) - 1) sets the level to 100%.

module wbs_pdm #(
	parameter BIT_RESOLUTION = 8,
	parameter CHANNEL_NUM = 0
) (
	// wishbone b4 pipelined
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire wb_cyc_i,
	input wire wb_stb_i,
	input wire wb_we_i,
	input wire [3:0] wb_adr_i,
	input wire [31:0] wb_dat_i,
	output wire [31:0] wb_dat_o,
	output wire wb_stall_o,
	output wire wb_ack_o,

	// pdm i/o, 1 bit per channel
	output [CHANNEL_NUM-1:0] pdm_channel
);
	wire request = wb_cyc_i & wb_stb_i & wb_we_i;
	wire unused = &{ wb_dat_i };

	assign { wb_stall_o, wb_dat_o } = 0;

	wbs_pdm_channel #(
		.BIT_RESOLUTION(BIT_RESOLUTION)
	) channel [CHANNEL_NUM-1:0] (
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_stb_i({ {CHANNEL_NUM-1{1'b0}}, request } << wb_adr_i),
		.wb_dat_i(wb_dat_i[BIT_RESOLUTION-1:0]),
		.pdm_channel(pdm_channel)
	);

	always @(posedge wb_clk_i) begin
		wb_ack_o <= wb_cyc_i && wb_stb_i;
	end
endmodule
