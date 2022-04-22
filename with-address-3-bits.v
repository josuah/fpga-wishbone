`default_nettype none

module top (
	input wire clk,
	output wire led_r,
	output wire led_g,
	output wire led_b
);
	wire wb_ack_o;
	wire wb_stall_o;

	reg [2:0] state = 0;
	reg [2:0] pwm_address = 0;

	localparam [2:0]
		STATE_RESET = 0,
		STATE_READY = 1,
		STATE_REQUEST = 2,
		STATE_WAIT_ACK = 3,
		STATE_END = 4;

	// control the leds over a wishbone bus
	wb_pwm #(
		.BITS(5),
		.CHANNELS(3)
	) pwm_leds (
		.wb_clk_i(clk),
		.wb_rst_i(state == STATE_RESET),
		.wb_stb_i(state == STATE_REQUEST),
		.wb_cyc_i(state >= STATE_REQUEST && state <= STATE_WAIT_ACK),
		.wb_we_i(1),
		.wb_adr_i({ 29'h0, pwm_address }),
		.wb_dat_i(
			pwm_address == 0 ? 32'hF :
			pwm_address == 1 ? 32'hF :
			pwm_address == 2 ? 32'hF :
			0
		),
		.wb_stall_o(wb_stall_o),
		.wb_ack_o(wb_ack_o),
		.pwm({ led_r, led_g, led_b })
	);

	// main state machine: issue requests over wishbone
	always @(posedge clk) begin
		case (state)
		STATE_REQUEST: begin
			if (!wb_stall_o)
				state <= state + 1;
		end
		STATE_WAIT_ACK: begin
			if (wb_ack_o)
				state <= state + 1;
		end
		STATE_END: begin
			// wraparound if not already at the end
			if (pwm_address < 2) begin
				state <= 1;
				pwm_address <= pwm_address + 1;
			end
		end
		default: begin
			state <= state + 1;
		end
		endcase
	end

endmodule
