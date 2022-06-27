`default_nettype none

module wbs_rgb (
	// wishbone b4 pipelined
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire wb_cyc_i,
	input wire wb_stb_i,
	input wire wb_we_i,
	input wire [3:0] wb_adr_i,
	input wire [3:0] wb_sel_i,
	input wire [31:0] wb_dat_i,
	output wire [31:0] wb_dat_o,
	output wire wb_stall_o,
	output reg wb_ack_o,

	// RGB LED
	output wire led_r,
	output wire led_g,
	output wire led_b
);
	reg enabled = 0;
	wire unused = |{ wb_we_i, wb_adr_i, wb_sel_i, wb_dat_i };

	assign wb_dat_o = 0;
	assign wb_stall_o = 0;

	assign led_r = enabled;
	assign led_g = enabled;
	assign led_b = enabled;

	always @(posedge wb_clk_i) begin
		wb_ack_o <= wb_cyc_i && wb_stb_i;

		if (wb_cyc_i && wb_stb_i)
			enabled <= 1;

		if (wb_rst_i)
			{ enabled } <= 0;
	end

endmodule
