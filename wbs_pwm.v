`default_nettype none

// Pulse-Width Modulation with 8bit resolution and adjustable frequency

// WB_CLK_HZ:
//	Inform the module of the value of the input clock.
//
// OUTPUT_HZ:
//	Clock speed in Hz of the output PWM.
//
// CHANNEL_NUM:
//	Number of pwm outputs privided through `pwm`. Affects the addresses
//	at which it is possible to write duty-cycle length data.
//
// 0x0000+[CHANNELS-1..0]:
//      One address per channel for setting the current duty cycle value.
//	Set to 0xFF is a 100% duty cycle.

module wbs_pwm #(
	parameter WB_CLK_HZ = 0,
	parameter OUTPUT_HZ = 0,
	parameter CHANNEL_NUM = 0
) (
	// wishbone b4 pipelined
	input wire wbs_clk_i,
	input wire wbs_rst_i,
	input wire wbs_cyc_i,
	input wire wbs_stb_i,
	input wire wbs_we_i,
	input wire [3:0] wbs_adr_i,
	input wire [31:0] wbs_dat_i,
	output wire [31:0] wbs_dat_o,
	output wire wbs_stall_o,
	output wire wbs_ack_o,

	// pwm i/o
	output wire [CHANNEL_NUM-1:0] pwm_channel
);
	localparam TICKS_PER_CYCLE = WB_CLK_HZ / OUTPUT_HZ;

	// one less bit, to permit reaching 100% duty cycle
	reg [7:0] counter1;
	reg [$clog2(TICKS_PER_CYCLE)-1:0] counter0;

	wire request = wbs_cyc_i & wbs_stb_i & wbs_we_i;
	wire unused = &{ wbs_dat_i };

	assign { wbs_stall_o, wbs_dat_o } = 0;

	wbs_pwm_channel channel [CHANNEL_NUM-1:0] (
		.wbs_clk_i(wbs_clk_i),
		.wbs_rst_i(wbs_rst_i),
		.wbs_stb_i({ {CHANNEL_NUM-1{1'b0}}, request } << wbs_adr_i),
		.wbs_dat_i(wbs_dat_i[7:0]),
		.pwm_counter(counter1),
		.pwm_channel(pwm_channel)
	);

	always @(posedge wbs_clk_i) begin
		wbs_ack_o <= wbs_cyc_i & wbs_stb_i;

		counter0 <= counter0 + 1;

		// start array at 8 to divide by 256, to compensate
		// the chained counter `counter1`
		if (counter0 == TICKS_PER_CYCLE[8 +: $size(counter0)]) begin
			counter0 <= 0;
			counter1 <= counter1 + 1;
		end

		if (wbs_rst_i)
			{ counter0, counter1 } <= 0;
	end

`ifdef FORMAL

	reg f_past_valid = 0;
	reg f_should_pulse = 0;

	always @(posedge wbs_clk_i) begin
		f_past_valid <= 1;

		if (wbs_stb_i)
			f_should_pulse <= 1;

		if (f_should_pulse)
			cover(|pwm);
	end

`endif

endmodule
