`default_nettype none

module wb_clock #(
	parameter WB_CLK_HZ = 0,
	parameter OUTPUT_HZ = 0
) (
	// Wishbone B4 subset
	input wire wb_clk_i,
	input wire wb_rst_i,

	// Clock output
	reg clock_out
);
	localparam TICKS_PER_HZ = WB_CLK_HZ / OUTPUT_HZ / 2;

	reg [$clog2(TICKS_PER_HZ)-1:0] counter = 0;

	always @(posedge wb_clk_i) begin
		counter <= counter + 1;
		if (counter == TICKS_PER_HZ) begin
			counter <= 0;
			clock_out <= !clock_out;
		end

		if (wb_rst_i)
			{ clock_out, counter } <= 0;
	end

`ifdef FORMAL
	assert property	(TICKS_PER_HZ > 0);
`endif

endmodule
