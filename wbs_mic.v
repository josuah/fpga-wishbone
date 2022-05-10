`default_nettype none

module wbs_mic #(
	parameter WB_CLK_HZ = 0,
	parameter MIC_CLK_HZ = 3000000,
	parameter AUDIO_BIT_DEPTH = 16
) (
	// wishbone b4 pipelined
	input wire wbs_clk_i,
	input wire wbs_rst_i,
	input wire wbs_cyc_i,
	input wire wbs_stb_i,
	input wire [3:0] wbs_adr_i,
	input wire [31:0] wbs_dat_i,
	output reg [31:0] wbs_dat_o,
	output wire wbs_stall_o,
	output reg wbs_ack_o,

	// interrupt
	output wire irq_mic_data_ready,

	// pdm microphone i/o
	output reg mic_clk,
	input wire mic_dat
);
	// wishbone b4 pipelined

	assign wbs_stall_o = 0;

	always @(posedge wbs_clk_i)
		wbs_ack_o <= wbs_cyc_i && wbs_stb_i;

	// pdm microphone I/O

	localparam TICKS_PER_HZ = WB_CLK_HZ / MIC_CLK_HZ / 2;

	reg [$clog2(TICKS_PER_HZ)-1:0] mic_clk_cnt = 0;
	reg [AUDIO_BIT_DEPTH-1:0] sample_buf = 0, sample_cnt = 0;

	always @(posedge wbs_clk_i) begin

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

				// continuously sample wbs_dat_o
				wbs_dat_o <= sample_buf;
				irq_mic_data_ready = 1;

				// not starting at zero because we add
				// the first value right away
				sample_cnt <= 1;
				sample_buf <= mic_dat ? 1 : 0;
			end
		end

		if (wbs_rst_i)
			{ mic_clk, mic_clk_cnt, sample_buf, sample_cnt } <= 0;
	end

`ifdef FORMAL
	assert property	(TICKS_PER_HZ > 0);
`endif

endmodule
