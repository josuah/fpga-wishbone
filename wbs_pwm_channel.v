`default_nettype none

module wbs_pwm_channel (
	// wishbone b4 pipeline
	input wire wb_rst_i,
	input wire wb_clk_i,
	input wire wb_stb_i,
	input wire [7:0] wb_dat_i,

	// pwm i/o
	input wire [7:0] pwm_counter,
	output wire pwm_channel
);
	reg [7:0] duty_cycle = 0;

	assign pwm_channel = duty_cycle > pwm_counter;

	always @(posedge wb_clk_i) begin
		if (wb_stb_i)
			duty_cycle <= wb_dat_i;

		if (wb_rst_i)
			duty_cycle <= 0;
	end

endmodule
