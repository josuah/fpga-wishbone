`default_nettype none

module wbs_pdm_channel #(
	parameter BIT_RESOLUTION = 0
) (
	input wire rst,
	input wire clk,
	input wire stb,
	input wire [BIT_RESOLUTION-1:0] data,
	output wire pdm_channel
);
	reg [BIT_RESOLUTION-1:0] level = 0;
	reg [BIT_RESOLUTION:0] accumulator = 0;

	assign pdm_channel = accumulator[BIT_RESOLUTION];

	always_ff @(posedge clk) begin
		accumulator <= accumulator[BIT_RESOLUTION-1:0] + level;

		if (stb)
			level <= data;

		if (rst)
			{ level, accumulator } <= 0;
	end

endmodule
