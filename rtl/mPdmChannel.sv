
module mPdmChannel#(
	parameter pBits = 0
)(
	input	logic rst,
	input	logic clk,
	input	iWishbone_Peri wb_p,
	input	iWishbone_Ctrl wb_c,
	output	logic pdm
);
	logic[pBits-1:0] level;
	logic[pBits:0] accumulator;

	assign pdm = accumulator[pBits];
	assign wb_p.ack = wb_p.stb;

	always_ff @(posedge clk) begin
		accumulator <= accumulator[pBits-1:0] + level;

		if (wb_c.stb) begin
			level <= wb_c.dat;
		end

		if (rst) begin
			{level, accumulator} <= 0;
		end
	end

endmodule
