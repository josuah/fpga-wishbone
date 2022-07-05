
// Pulse-Width Modulation with 8bit resolution and adjustable frequency

// pWbHz:
//	Inform the module of the value of the input clock.
//
// pOutHz:
//	Clock speed in Hz of the output PWM.
//
// pChannels:
//	Number of pwm outputs privided through `pwm`. Affects the addresses
//	at which it is possible to write duty-cycle length data.
//
// 0x0000+[CHANNELS-1..0]:
//      One address per channel for setting the current duty cycle value.
//	Set to 0xFF is a 100% duty cycle.

module mPwm#(
	parameter pWbHz = 0,
	parameter pOutHz = 0,
	parameter pChannels = 0
) (
	iWishbone.mPeri wb,
	output logic[pChannels-1:0] pwm
);
	localparam lpTicksPerCycle = pWbHz / pOutHz;

	// one less bit, to permit reaching 100% duty cycle
	logic[7:0] counter1;
	logic[$clog2(lpTicksPerCycle)-1:0] counter0;
	logic request;
	logic unused = &{ wb.dat };

	assign wb.dat_p = 0;
	assign request = wb.stb & wb.we;

	mPwmChannel mchannel[pChannels-1:0] (
		.clk(wb.clk),
		.rst(wb.rst),
		.stb({ {pChannels-1{1'b0}}, request } << wb.adr),
		.data(wb.dat_c[7:0]),
		.pwm_counter(counter1),
		.pwm(pwm)
	);

	always_ff @(posedge wb.clk) begin
		wb.ack <= wb.stb;

		counter0 <= counter0 + 1;

		// start array at 8 to divide by 256, to compensate
		// the chained counter `counter1`
		if (counter0 == lpTicksPerCycle[8 +: $size(counter0)]) begin
			counter0 <= 0;
			counter1 <= counter1 + 1;
		end

		if (wb.rst) begin
			{ counter0, counter1 } <= 0;
		end
	end

`ifdef FORMAL

	logic f_past_valid = 0;
	logic f_should_pulse = 0;

	always_ff @(posedge wb.clk) begin
		f_past_valid <= 1;

		if (wb.stb)
			f_should_pulse <= 1;

		if (f_should_pulse)
			cover(|pwm);
	end

`endif

endmodule
