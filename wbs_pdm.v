`default_nettype none

// Pulse Density Modulation module

// CHANNEL_NUM:
//	Number of PDM outputs provided through `pdm`. Affects the addresses
//	at which it is possible to write duty-cycle length data.
//
// Wishbone address 0x0 to CHANNEL_NUM-1:
//      One address per channel for setting the level.
//	wbs_dat_o set at ((1 << BIT_RESOLUTION) - 1) sets the level to 100%.

module wbs_pdm #(
	parameter BIT_RESOLUTION = 8,
	parameter CHANNEL_NUM = 0
) (
	// wishbone b4 pipelined
	input wire wbs_clk_i,
	input wire wbs_rst_i,
	input wire wbs_cyc_i,
	input wire wbs_stb_i,
	input wire wbs_we_i,
	input wire [3:0] wbs_adr_i,
	input wire [31:0] wbs_dat_i,
	output wire [31:0] wbs_dat_o,
	output wire wbs_stall_o,
	output wire wbs_ack_o,

	// pdm i/o, 1 bit per channel
	output [CHANNEL_NUM-1:0] pdm_channel
);
	wire request = wbs_cyc_i & wbs_stb_i & wbs_we_i;
	wire unused = &{ wbs_dat_i };

	assign { wbs_stall_o, wbs_dat_o } = 0;

	wbs_pdm_channel #(
		.BIT_RESOLUTION(BIT_RESOLUTION)
	) channel [CHANNEL_NUM-1:0] (
		.wbs_clk_i(wbs_clk_i),
		.wbs_rst_i(wbs_rst_i),
		.wbs_stb_i({ {CHANNEL_NUM-1{1'b0}}, request } << wbs_adr_i),
		.wbs_dat_i(wbs_dat_i[BIT_RESOLUTION-1:0]),
		.pdm_channel(pdm_channel)
	);

	always @(posedge wbs_clk_i) begin
		wbs_ack_o <= wbs_cyc_i && wbs_stb_i;
	end
endmodule
