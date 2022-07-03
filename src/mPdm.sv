`default_nettype none

// Pulse Density Modulation module

// CHANNEL_NUM:
//	Number of PDM outputs provided through `pdm`. Affects the addresses
//	at which it is possible to write duty-cycle length data.
//
// Wishbone address 0x0 to CHANNEL_NUM-1:
//      One address per channel for setting the level.
//	wb.dat_p set at ((1 << BIT_RESOLUTION) - 1) sets the level to 100%.

module wbs_pdm #(
	parameter BIT_RESOLUTION = 8,
	parameter CHANNEL_NUM = 0
) (
	wishbone wb,
	output [CHANNEL_NUM-1:0] pdm_channel
);
	wire request;
	wire unused = &{ wb.dat_c };

	assign { wb.dat_p } = 0;
	assign request = wb.stb & wb.we;

	wbs_pdm_channel #(
		.BIT_RESOLUTION(BIT_RESOLUTION)
	) channel [CHANNEL_NUM-1:0] (
		.wb.clk(wb.clk),
		.wb.rst(wb.rst),
		.wb.stb({ {CHANNEL_NUM-1{1'b0}}, request } << wb.adr),
		.wb.dat_c(wb.dat_c[BIT_RESOLUTION-1:0]),
		.pdm_channel(pdm_channel)
	);

	always_ff @(posedge wb.clk) begin
		wb.ack <= wb.stb;
	end
endmodule
