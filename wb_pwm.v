`default_nettype none

/*
 * BITS:
 *      Length of the PWM counter and duty-cycle. Increasing the
 *	number of bits also increases the duration between two cycles:
 *	reduces the frequency.
 *
 * CHANNELS:
 *	Number of pwm outputs privided through `pwm`. Affects the addresses
 *	at which it is possible to write duty-cycle length data.
 *
 * 0x0000+i*4 i=[CHANNELS-1..0]:
 *	Duty cycle value, with `i` the number of the PWM chanel.
 *	Value between `0` (0%) and `1 << BITS-1` (100%) inclusive.
 */

module wb_pwm #(
	parameter BITS = 4,
	parameter CHANNELS = 3
) (
	// Wishbone B4 pipelined
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire wb_cyc_i,
	input wire wb_stb_i,
	input wire wb_we_i,
	input wire [31 : 0] wb_adr_i,
	input wire [31 : 0] wb_dat_i,
	output wire [31 : 0] wb_dat_o,
	output wire wb_ack_o,
	output wire wb_stall_o,

	// PWM output
	output wire [CHANNELS-1:0] pwm
);
	// one less bit, to permit reaching 100% duty cycle
	reg [BITS-1:0] counter;
	wire [31:BITS] unused = { wb_dat_i[31:BITS] };
	wire request = wb_cyc_i & wb_stb_i & wb_we_i;
	wire [CHANNELS-1:0] channel_sel = 2{1'b0} request << wb_adr_i[$clog2(CHANNELS):0];

	assign wb_stall_o = 0;
	assign wb_dat_o = 0;

	wb_pwm_channel #(
		.BITS(BITS)
	) channel[CHANNELS-1:0] (
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_stb_i(channel_sel),
		.wb_dat_i(wb_dat_i[BITS-1:0]),
		.pwm_counter(counter),
		.pwm_channel(pwm)
	);

	always @(posedge wb_clk_i) begin
		wb_ack_o <= wb_cyc_i & wb_stb_i;
		counter <= counter + 1;

		if (wb_rst_i)
			counter <= 0;
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
