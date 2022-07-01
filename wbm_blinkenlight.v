module wbm_blinkenlight (
	// Reduced Wishbone B4 pipelined
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire wb_cyc_o,
	input wire wb_stb_o,
	input wire wb_stall_i,
	input wire wb_ack_i,
	input wire wb_we_o,
	input wire [3:0] wb_sel_o,
	input wire [15:0] wb_adr_o,
	input wire [31:0] wb_dat_o,
	input wire [31:0] wb_dat_i,

	// Pretty Debug Blinkenlights
	output [7:0] blinkenlight
);
	reg [3:0] counter = 0;
	reg request = 0, we = 0, dat_o = 0, dat_i = 0;
	wire unused = |{ wb_rst_i, wb_cyc_o, wb_sel_o, wb_adr_o, wb_stall_i };

	assign blinkenlight = { counter, request, we, dat_o, dat_i };

	always @(posedge wb_clk_i) begin
		if (wb_ack_i) begin
			counter <= counter + 1;
			dat_i <= |wb_dat_i;
			dat_o <= 0;
			request <= 0;
		end
		if (wb_stb_o) begin
			dat_o <= |wb_dat_o;
			dat_i <= 0;
			we <= wb_we_o;
			request <= 1;
		end
	end

endmodule
