
module mPwmChannel (
	input logic rst,
	input logic clk,
	input logic stb,
	input logic[7:0] data,
	input logic[7:0] pwm_counter,
	output logic pwm
);
	logic[7:0] duty_cycle;

	assign pwm = duty_cycle > pwm_counter;

	always_ff @(posedge clk) begin
		if (stb) begin
			duty_cycle <= dat;
		end

		if (rst) begin
			duty_cycle <= 0;
		end
	end

endmodule
