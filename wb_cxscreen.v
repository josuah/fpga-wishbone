`default_nettype none

module wb_cxscreen (
	// Wishbone B4 pipelined
	input wire wb_clk_i,

	// Screen output pins
	output wire [6:0] cxscreen_o,
	output wire [6:0] cxscreen_oe
);
//	reg [6:0] row = 3;
//	reg [6:0] col = 4;

//	wire [6:0] row_pin = row - (row == col ? 1 : 0);
//	wire [6:0] col_pin = col;

	assign cxscreen_o =	7'b0010000;
	assign cxscreen_oe =	7'b0011000;

//	always @(posedge *) begin
//		row < row + 1;
//
//		if (row == 5) begin
//			row <= 0;
//			col <= col + 1;
//		end
//
//		if (col == 7) begin
//			col <= 0;
//		end
//	end

endmodule
