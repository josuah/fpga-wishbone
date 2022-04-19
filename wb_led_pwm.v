`default_nettype none

module wb_led_pwm (
	// Wishbone B4
	input wire i_wb_clk,
	input wire i_wb_rst,
	input wire i_wb_cyc,
	input wire i_wb_stb,
	input wire i_wb_we,
	input wire [31:0] i_wb_addr,
	input wire [31:0] i_wb_data,
	output wire [31:0] o_wb_data,
	output wire o_wb_stall,
	output reg o_wb_ack,

	// Board
	output wire o_led_r,
	output wire o_led_g,
	output wire o_led_b
);
	wire [23:0] unused = { i_wb_data[31:24], i_wb_addr[15:0] };
	wire write_request = (i_wb_cyc && i_wb_stb && i_wb_we);

	reg r_wb_ack;
	reg [7:0] counter, pwm_g, pwm_r, pwm_b;

	assign o_wb_data = 0;
	assign o_wb_stall = 0;
	assign o_led_r = (pwm_r > counter);
	assign o_led_g = (pwm_g > counter);
	assign o_led_b = (pwm_b > counter);

	always @(posedge i_wb_clk) begin
		o_wb_ack <= r_wb_ack;

		counter <= counter + 1;

		if (write_request) begin
			pwm_r <= i_wb_data[23:16];
			pwm_g <= i_wb_data[15:8];
			pwm_b <= i_wb_data[7:0];
		end
		r_wb_ack <= write_request;

		if (i_wb_rst)
			{ counter, pwm_g, pwm_r, pwm_b } <= 0;
	end
endmodule
