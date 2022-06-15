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
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire wb_cyc_i,
	input wire wb_stb_i,
	input wire wb_we_i,
	input wire [3:0] wb_adr_i,
	input wire [31:0] wb_dat_i,
	output wire [31:0] wb_dat_o,
	output wire wb_stall_o,
	output wire wb_ack_o,

	// pwm i/o
	output wire [CHANNEL_NUM-1:0] pwm_channel
);
	localparam TICKS_PER_CYCLE = WB_CLK_HZ / OUTPUT_HZ;
	// one less bit, to permit reaching 100% duty cycle
	reg [7:0] counter1;
	reg [$clog2(TICKS_PER_CYCLE)-1:0] counter0;
	wire request;
	wire unused = &{ wb_dat_i };

	assign { wb_stall_o, wb_dat_o } = 0;
	assign request = wb_cyc_i & wb_stb_i & wb_we_i;

	wbs_pwm_channel channel [CHANNEL_NUM-1:0] (
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_stb_i({ {CHANNEL_NUM-1{1'b0}}, request } << wb_adr_i),
		.wb_dat_i(wb_dat_i[7:0]),
		.pwm_counter(counter1),
		.pwm_channel(pwm_channel)
	);

	always @(posedge wb_clk_i) begin
		wb_ack_o <= wb_cyc_i & wb_stb_i;

		counter0 <= counter0 + 1;

		// start array at 8 to divide by 256, to compensate
		// the chained counter `counter1`
		if (counter0 == TICKS_PER_CYCLE[8 +: $size(counter0)]) begin
			counter0 <= 0;
			counter1 <= counter1 + 1;
		end

		if (wb_rst_i)
			{ counter0, counter1 } <= 0;
	end

`ifdef FORMAL

	reg f_past_valid = 0;
	reg f_should_pulse = 0;

	always @(posedge wb_clk_i) begin
		f_past_valid <= 1;

		if (wb_stb_i)
			f_should_pulse <= 1;

		if (f_should_pulse)
			cover(|pwm);
	end

`endif

endmodule
