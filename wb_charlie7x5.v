// TODO: split the design with the wishbone front-end at the top
//	simplifying it and enforcing rules, so that this block can
//	be copy-pasted from module to module, and implementation
//	below.

`default_nettype none

module wb_charlie7x5 #(
	parameter WB_CLK_HZ = 48_000_000,
	parameter MEM_SIZE = 1 << $clog2(5)
) (
	// Wishbone B4 pipelined
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire wb_cyc_i,
	input wire wb_stb_i,
	input wire wb_we_i,
	input wire wb_adr_i,
	input wire wb_dat_i,
	output wire wb_dat_o,
	output wire wb_stall_o,
	output reg wb_ack_o,

	// Screen output pins
	output wire [6:0] charlie7x5_o,
	output wire [6:0] charlie7x5_oe
);
	reg [MEM_SIZE-1:0] mem [0:4];
	reg [2:0] row = 0;
	reg [2:0] col = 0;
	reg [$clog2(WB_CLK_HZ / 100000):0] tick = 0;

	wire [2:0] row_pin = (row >= col) ? row + 1 : row;
	wire [2:0] col_pin = col;
	wire dot = mem[row][col];
	wire request = wb_cyc_i && wb_stb_i;

	assign wb_stall_o = 0;
	assign charlie7x5_o = dot
		? (1 << row_pin)
		: 0;
	assign charlie7x5_oe = dot
		? (1 << row_pin) | (1 << col_pin)
		: 0;

	always @(posedge wb_clk_i) begin
		wb_ack_o <= request;

		tick <= tick + 1;
		if (tick == 0) begin
			if (row == 4) begin
				row <= 0;
			end else begin
				row <= row + 1;
			end
			row <= (row == 4) ? 0 : row + 1;
			col <= (row == 4) ? col : (col == 6) ? 0 : col + 1;
		end

		if (request && wb_we_i)
			mem[wb_adr_i] <= wb_dat_i;
		if ()
			wb_err_i <= 1;

		if (wb_rst_i)
			{ row, col } <= 0;
	end
endmodule
