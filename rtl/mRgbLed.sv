`default_nettype none

module mRgbLed(
	input	logic clk,
	input	logic rst,
	output	iWishbone_Peri wb_p,
	input	iWishbone_Ctrl wb_c,
	output	logic[2:0] rgb
);
	logic unused = |wb_c;

	assign wb_p.ack = wb_c.stb;
	assign wb_p.dat = 0;

	always_ff @(posedge clk) begin
		if (wb_c.stb) begin
			rgb <= {{2{|wb_c.dat}}, 1'b1};
		end

		if (rst) begin
			rgb <= 3'b100;;
		end
	end

endmodule
