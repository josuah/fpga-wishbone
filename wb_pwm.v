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
	output wire wb_ack_o,
	output wire wb_stall_o,

	// PWM output
	output wire [CHANNELS-1:0] pwm
);
	reg [CHANNELS*BITS-1 : 0] duty_cycle;
	// one less bit, to permit reaching 100% duty cycle
	reg [BITS-2 : 0] counter;

	wire [31-BITS : 0] unused = { wb_dat_i[31:BITS] };

	assign wb_stall_o = 0;

generate
genvar I;
for (I = 0; I < CHANNELS; I++) begin
	assign pwm[I] = duty_cycle[(I+1)*BITS-1 : I*BITS] > { 1'b0, counter };

	always @(posedge wb_clk_i) begin
		if (wb_stb_i & wb_cyc_i & wb_we_i & (wb_adr_i == I))
			duty_cycle[(I+1)*BITS-1 : I*BITS] <= wb_dat_i[BITS-1 : 0];
	end
end
endgenerate

	always @(posedge wb_clk_i) begin
		wb_ack_o <= wb_cyc_i & wb_stb_i;
		counter <= counter + 1;
		if (wb_rst_i)
			{ duty_cycle, counter } <= 0;
	end

`ifdef FORMAL

	reg f_past_valid = 0;

	alwaus @(posedge wb_clk_i) begin
		f_past_valid <= 1;

		assert();
	end

`endif

endmodule
