`default_nettype none

module wbs_debug (
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

	// Debug LEDs
	output reg [7:0] debug
);
	wire unused = |{ wb_we_i, wb_adr_i, wb_sel_i, wb_dat_i };

	assign wb_dat_o = 0;
	assign wb_stall_o = 0;

	always @(posedge wb_clk_i) begin
		wb_ack_o <= wb_cyc_i && wb_stb_i;
		if (wb_cyc_i && wb_stb_i && wb_we_i)
			debug <= 8'hFF;

		if (wb_rst_i)
			{ debug } <= 0;
	end

endmodule
