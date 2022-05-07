`default_nettype none

module wb_mic #(
	parameter WB_CLK_HZ = 0,
	parameter MIC_CLK_HZ = 3000000,
	parameter AUDIO_BIT_DEPTH = 16
) (
	// Wishbone B4 Pipelined
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire wb_cyc_i,
	input wire wb_stb_i,
	input wire wb_adr_i,
	input wire wb_dat_i,
	output reg wb_dat_o,
	output wire wb_stall_o,
	output reg wb_ack_o,

	// PDM Microphone I/O
	output reg mic_clk,
	input wire mic_dat
);
	// Wishbone B4 Pipelined

	always @(posedge wb_clk_i) begin
		wb_ack_o <= wb_cyc_i && wb_stb_i;
	end

	// PDM microphone I/O

	localparam TICKS_PER_HZ = WB_CLK_HZ / OUTPUT_HZ / 2;

	reg [$clog2(TICKS_PER_HZ)-1:0] mic_clk_cnt = 0;
	reg [AUDIO_BIT_DEPTH-1:0] sample_buf = 0, sample_cnt = 0;

	always @(posedge wb_clk_i) begin
		mic_clk_cnt <= mic_clk_cnt + 1;
		if (mic_clk_cnt == TICKS_PER_HZ) begin
			mic_clk_cnt <= 0;
			mic_clk <= !mic_clk;
		end

		if (mic_clk_cnt == 0 && mic_clk == 1) begin
			sample_buf <= sample_buf + mic_dat ? 1 : 0;
			sample_cnt <= sample_cnt + 1;
			if (sample_cnt + 1 == 0) begin
				wb_dat_o <= sample_buf;
				sample_buf <= mic_dat ? 1 : 0;
				sample_cnt <= 1;  // not starting at zero
			end
		end

		if (wb_rst_i)
			{ mic_clk, mic_clk_cnt, sample_buf, sample_cnt } <= 0;
	end

`ifdef FORMAL
	assert property	(TICKS_PER_HZ > 0);
`endif

endmodule
