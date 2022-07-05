
module mPdmChannel#(
	parameter pBits = 0
) (
	input logic rst,
	input logic clk,
	input logic stb,
	input logic[pBits-1:0] data,
	output logic pdm
);
	logic[pBits-1:0] level;
	logic[pBits:0] accumulator;

	assign pdm = accumulator[pBits];

	always_ff @(posedge clk) begin
		accumulator <= accumulator[pBits-1:0] + level;

		if (stb) begin
			level <= data;
		end

		if (rst) begin
			{ level, accumulator } <= 0;
		end
	end

endmodule
