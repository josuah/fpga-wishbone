`default_nettype none

module wb_pdm_channel #(
	parameter BIT_RESOLUTION = 0
) (
	// Wishbone B4 pipeline
	input wire wb_rst_i,
	input wire wb_clk_i,
	input wire wb_stb_i,
	input wire [BIT_RESOLUTION-1:0] wb_dat_i,

	// PDM I/O
	output wire pdm_channel
);
	reg [BIT_RESOLUTION-1:0] level = 0;
	reg [BIT_RESOLUTION:0] accumulator = 0;

	assign pdm_channel = accumulator[BIT_RESOLUTION];

	always @(posedge wb_clk_i) begin
		accumulator <= accumulator[BIT_RESOLUTION-1:0] + level;

		if (wb_stb_i)
			level <= wb_dat_i;
		if (wb_rst_i)
			{ level, accumulator } <= 0;
	end
endmodule
