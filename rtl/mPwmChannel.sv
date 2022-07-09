`default_nettype none

module mPwmChannel#(
	parameter pClkHz = 0,
	parameter pOutHz = 0,
	parameter pChannels = 0
) (
	input	logic clk,
	input	logic rst,
	output	iWishbone_Peri wb_p,
	input	iWishbone_Ctrl wb_c,
	output	logic[pChannels-1:0] pwm
);
	localparam pTicksPerCycle = pClkHz / pOutHz;

	// one less bit, to permit reaching 100% duty cycle
	logic[$clog2(pTicksPerCycle)-1:0] cnt0;
	logic[7:0] cnt1;
	logic[7:0] duty_cycle;

	assign pwm = duty_cycle > cnt1;
	assign wb_p.ack = wb_c.stb;

	always_ff @(posedge clk) begin

		if (wb_c.stb) begin
			duty_cycle <= wb_c.dat;
		end

		cnt0 <= cnt0 + 1;
		if (cnt0 == pTicksPerCycle[8 +: $size(cnt0)]) begin
			cnt0 <= 0;
			cnt1 <= cnt1 + 1;
		end

		if (rst) begin
			{cnt0, cnt1, duty_cycle} <= 0;
		end
	end

endmodule
