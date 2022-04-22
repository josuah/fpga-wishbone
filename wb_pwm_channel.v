`default_nettype none

module wb_pwm_channel #(
	parameter BITS = 4
) (
	// Wishbone B4 pipeline
	input wire wb_rst_i,
	input wire wb_clk_i,
	input wire wb_stb_i,
	input wire [BITS-1:0] wb_dat_i,

	// PWM I/O
	input wire [BITS-1:0] pwm_counter,
	output wire pwm_channel
);
	reg [BITS-1:0] duty_cycle = 0;

	assign pwm_channel = duty_cycle > pwm_counter;

	always @(posedge wb_clk_i) begin
		if (wb_stb_i)
			duty_cycle <= wb_dat_i[BITS-1:0];
		if (wb_rst_i)
			duty_cycle <= 0;
	end
endmodule
