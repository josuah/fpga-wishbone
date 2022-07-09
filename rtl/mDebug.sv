`default_nettype none

module mDebug (
	input	logic clk,
	input	logic rst,
	output	iWishbone_Peri wb_p,
	input	iWishbone_Ctrl wb_c,
	output	logic[7:0] debug
);
	assign wb_p.dat = 0;

	always_ff @(posedge clk) begin
		wb_p.ack <= wb_c.stb;

		if (wb_c.stb && wb_c.we) begin
			debug <= wb_c.dat;
		end

		if (rst) begin
			debug <= 8'b11011011;
		end
	end

endmodule
