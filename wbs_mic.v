`default_nettype none

module wbs_mic #(
	parameter WB_CLK_HZ = 0,
	parameter MIC_CLK_HZ = 3000000,
	parameter AUDIO_BIT_DEPTH = 16
) (
	// wishbone b4 pipelined
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire wb_cyc_i,
	input wire wb_stb_i,
	input wire [3:0] wb_adr_i,
	input wire [31:0] wb_dat_i,
	output reg [31:0] wb_dat_o,
	output wire wb_stall_o,
	output reg wb_ack_o,

	// interrupt
	output wire irq_mic_data_ready,

	// pdm microphone i/o
	output reg mic_clk,
	input wire mic_dat
);
	localparam TICKS_PER_HZ = WB_CLK_HZ / MIC_CLK_HZ / 2;
	reg [$clog2(TICKS_PER_HZ)-1:0] mic_clk_cnt = 0;
	reg [AUDIO_BIT_DEPTH-1:0] sample_buf = 0, sample_cnt = 0;

	assign wb_stall_o = 0;

	always @(posedge wb_clk_i) begin
		wb_ack_o <= wb_cyc_i && wb_stb_i;

		// clock divider out to the microphone clock pin
		mic_clk_cnt <= mic_clk_cnt + 1;
		if (mic_clk_cnt == TICKS_PER_HZ) begin
			mic_clk_cnt <= 0;
			mic_clk <= !mic_clk;
		end

		irq_mic_data_ready = 0;
		if (mic_clk_cnt == 0 && mic_clk == 1) begin
			sample_buf <= sample_buf + mic_dat ? 1 : 0;
			sample_cnt <= sample_cnt + 1;

			// if next sample would overflow
			if (sample_cnt + 1 == 0) begin

				// continuously sample wb_dat_o
				wb_dat_o <= sample_buf;
				irq_mic_data_ready = 1;

				// not starting at zero because we add
				// the first value right away
				sample_cnt <= 1;
				sample_buf <= mic_dat ? 1 : 0;
			end
		end

		if (wb_rst_i)
			{ mic_clk, mic_clk_cnt, sample_buf, sample_cnt } <= 0;
	end

`ifdef FORMAL
	assert property	(TICKS_PER_HZ > 0);
`endif

endmodule
