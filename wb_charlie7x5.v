// TODO: split the design with the wishbone front-end at the top
//	simplifying it and enforcing rules, so that this block can
//	be copy-pasted from module to module, and implementation
//	below.

`default_nettype none

module wb_charlie7x5 #(
	parameter WB_CLK_HZ = 48_000_000,
	parameter MEM_SIZE = 1 << $clog2(5)
) (
	// wishbone b4 pipelined
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire wb_cyc_i,
	input wire wb_stb_i,
	input wire wb_we_i,
	input wire [3:0] wb_adr_i,
	input wire [31:0] wb_dat_i,
	output wire wb_dat_o,
	output wire wb_stall_o,
	output reg wb_ack_o,

	// charlie7x5
	output wire [6:0] charlie7x5_o,
	output wire [6:0] charlie7x5_oe
);
	wire unused = &{ wb_adr_i[3], wb_dat_i[31:8] };


	// wishbone //

	wire wb_request = wb_cyc_i && wb_stb_i;

	assign wb_dat_o = 0;
	assign wb_stall_o = 0;

	always @(posedge wb_clk_i)
		wb_ack_o <= wb_request;


	// charlie7x5 //

	// cursor for the current pixel being lit or not lit
	reg [2:0] row = 0;
	reg [2:0] col = 0;

	// clock divider for reducing the refresh rate
	localparam DELAY_HZ = 100000;
	reg [$clog2(WB_CLK_HZ / DELAY_HZ)-1:0] cnt = 0;

	// row and col use the same pins, with priority to the cols,
	// and the row shifted by one when they overlap
	wire [2:0] col_pin = col;
	wire [2:0] row_pin = (row < col) ? row : row + 1;

	// is the current pixel on or off?
	wire dot = mem_rd[0]; //col];

	assign charlie7x5_o = dot ? (1 << row_pin) : 0;
	assign charlie7x5_oe = dot ? (1 << row_pin) | (1 << col_pin) : 0;

	// memory for the screen pixels
	localparam ADDR_SIZE = $clog2(MEM_SIZE);
	reg [MEM_SIZE-1:0] mem [4:0], mem_wr, mem_rd;
	wire [ADDR_SIZE-1:0] mem_wr_addr = wb_adr_i[ADDR_SIZE-1:0];
	wire [ADDR_SIZE-1:0] mem_rd_addr = col;
	always @(posedge wb_clk_i) mem[mem_wr_addr] <= mem_wr;
	always @(posedge wb_clk_i) mem_rd <= mem[mem_rd_addr];

	always @(posedge wb_clk_i) begin
		// scale the clock down
		cnt <= cnt + 1;
		if (cnt == 0) begin
			// scan rows one byu one to set a single
			// pixel of the row high or low
			row <= row + 1;

			// why do I have to set it to 5 and not 4?
			// it behaves differently in hardware and
			// software
			if (row == 4) begin
				row <= 0;

				// once the row is complete, switch
				// to the next column
				col <= (col == 6) ? 0 : col + 1;
			end
		end

		if (wb_request && wb_we_i)
			mem_wr <= wb_dat_i[7:0];

		if (wb_rst_i)
			{ row, col, cnt, mem_wr, mem_rd } <= 0;
	end

endmodule
