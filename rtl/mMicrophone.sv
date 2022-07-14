`default_nettype none

module mMicrophone#(
	parameter pWbHz = 0,
	parameter pMicHz = 3000000,
	parameter pAudioBits = 16
) (
	input	logic clk,
	output	logic rst,
	output	iWishbone_Peri wb_p,
	input	iWishbone_Ctrl wb_c,
	output	logic mic_clk,
	input	logic mic_data,
	output	logic irq
);
	localparam pTicksPerHz = pWbHz / pMicHz / 2;

	logic[$clog2(pTicksPerHz)-1:0] mic_clk_cnt;
	logic[pAudioBits-1:0] sampling_buf, sampling_cnt;

	assign wb_p.ack = wb_c.stb;

	always_ff @(posedge clk) begin

		// clock divider out to the microphone clock pin
		mic_clk_cnt <= mic_clk_cnt + 1;
		if (mic_clk_cnt == pTicksPerHz) begin
			mic_clk_cnt <= 0;
			clk <= !clk;
		end

		irq = 0;
		if (mic_clk_cnt == 0 && clk == 1) begin
			sampling_buf <= sampling_buf + mic_data ? 1 : 0;
			sampling_cnt <= sampling_cnt + 1;

			// if next sampling would overflow
			if (sampling_cnt + 1 == 0) begin

				// continuously sampling wb_p.dat
				wb_p.dat <= sampling_buf;
				irq = 1;

				// not starting at zero because we add
				// the first value right away
				sampling_cnt <= 1;
				sampling_buf <= mic_data ? 1 : 0;
			end
		end

		if (rst) begin
			{mic_clk, mic_clk_cnt, sampling_buf, sampling_cnt} <= 0;
		end
	end
endmodule
