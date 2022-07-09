
module mRgbLed(
	input	logic clk,
	input	logic rst,
	output	iWishbone_Peri wb_p,
	input	iWishbone_Ctrl wb_c,
	output	logic[2:0] rgb
);
	assign wb_p.ack = wb_c.stb;

	always_ff @(posedge clk) begin
		if (wb_c.stb) begin
			rgb <= 3'b111;
		end

		if (rst) begin
			rgb <= 0;
		end
	end

endmodule
