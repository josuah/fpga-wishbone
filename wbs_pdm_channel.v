`default_nettype none

module wbs_pdm_channel #(
	parameter BIT_RESOLUTION = 0
) (
	// wishbone b4 pipeline
	input wire wbs_rst_i,
	input wire wbs_clk_i,
	input wire wbs_stb_i,
	input wire [BIT_RESOLUTION-1:0] wbs_dat_i,

	// pdm i/o
	output wire pdm_channel
);
	reg [BIT_RESOLUTION-1:0] level = 0;
	reg [BIT_RESOLUTION:0] accumulator = 0;

	assign pdm_channel = accumulator[BIT_RESOLUTION];

	always @(posedge wbs_clk_i) begin
		accumulator <= accumulator[BIT_RESOLUTION-1:0] + level;

		if (wbs_stb_i)
			level <= wbs_dat_i;
		if (wbs_rst_i)
			{ level, accumulator } <= 0;
	end
endmodule
