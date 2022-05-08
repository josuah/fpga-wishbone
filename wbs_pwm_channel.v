`default_nettype none

module wbs_pwm_channel (
	// wishbone b4 pipeline
	input wire wbs_rst_i,
	input wire wbs_clk_i,
	input wire wbs_stb_i,
	input wire [7:0] wbs_dat_i,

	// pwm i/o
	input wire [7:0] pwm_counter,
	output wire pwm_channel
);
	reg [7:0] duty_cycle = 0;

	assign pwm_channel = duty_cycle > pwm_counter;

	always @(posedge wbs_clk_i) begin
		if (wbs_stb_i)
			duty_cycle <= wbs_dat_i;
		if (wbs_rst_i)
			duty_cycle <= 0;
	end
endmodule
