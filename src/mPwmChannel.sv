`default_nettype none

module wbs_pwm_channel (
	// wishbone b4 pipeline
	input wire rst,
	input wire clk,
	input wire stb,
	input wire [7:0] data,

	// pwm i/o
	input wire [7:0] pwm_counter,
	output wire pwm_channel
);
	reg [7:0] duty_cycle = 0;

	assign pwm_channel = duty_cycle > pwm_counter;

	always_ff @(posedge clk) begin
		if (stb)
			duty_cycle <= dat;

		if (rst)
			duty_cycle <= 0;
	end

endmodule
