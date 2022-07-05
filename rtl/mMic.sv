
module mMic#(
	parameter pWbHz = 0,
	parameter pMicHz = 3000000,
	parameter pAudioBits = 16
) (
	iWishbone.mPeri wb,
	output logic irq,
	output logic clk,
	input logic data
);
	localparam lpTicksPerHz = pWbHz / pMicHz / 2;

	logic[$clog2(lpTicksPerHz)-1:0] clk_cnt;
	logic[pAudioBits-1:0] sampling_buf, sampling_cnt;

	always_ff @(posedge wb.clk) begin
		wb.ack <= wb.stb;

		// clock divider out to the microphone clock pin
		clk_cnt <= clk_cnt + 1;
		if (clk_cnt == lpTicksPerHz) begin
			clk_cnt <= 0;
			clk <= !clk;
		end

		irq_mic_data_ready = 0;
		if (clk_cnt == 0 && clk == 1) begin
			sampling_buf <= sampling_buf + mic_dat ? 1 : 0;
			sampling_cnt <= sampling_cnt + 1;

			// if next sampling would overflow
			if (sampling_cnt + 1 == 0) begin

				// continuously sampling wb.dat_p
				wb.dat_p <= sampling_buf;
				irq_mic_data_ready = 1;

				// not starting at zero because we add
				// the first value right away
				sampling_cnt <= 1;
				sampling_buf <= mic_dat ? 1 : 0;
			end
		end

		if (wb.rst)
			{ clk, clk_cnt, sampling_buf, sampling_cnt } <= 0;
	end

`ifdef FORMAL
	assert property	(lpTicksPerHz > 0);
`endif

endmodule
