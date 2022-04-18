module board (
	output wire rgb0,
	output wire rgb1,
	output wire rgb2,
	output wire gpio_26,
	output wire gpio_27
);
	wire clk;
	wire led_r, led_g, led_b;
	wire pwm_ack;
	wire pwm_stall;

	reg [2:0] state = 0;
	reg [31:0] pwm_address = 0;

	assign gpio_26 = 0;
	assign gpio_27 = 0;

	localparam [2:0]
		STATE_RESET = 0,
		STATE_READY = 1,
		STATE_REQUEST = 2,
		STATE_WAIT_ACK = 3,
		STATE_END = 4;

	// internal oscillator
	SB_HFOSC SB_HFOSC (
		.CLKHFPU(1'b1),
		.CLKHFEN(1'b1),
		.CLKHF(clk)
	);

	// RGB primitive with control of the current
	SB_RGBA_DRV #(
		.RGB0_CURRENT("0b000001"),
		.RGB1_CURRENT("0b000001"),
		.RGB2_CURRENT("0b000001")
	) sb_rgba_drv (
		.RGBLEDEN(1'b1),
		.RGB0PWM(led_g),
		.RGB1PWM(led_b),
		.RGB2PWM(led_r),
		.CURREN(1'b1),
		.RGB0(rgb0),
		.RGB1(rgb1),
		.RGB2(rgb2)
	);

	// control the leds over a wishbone bus
	wb_pwm #(
		.BITS(2),
		.CHANNELS(3)
	) pwm_leds (
		.wb_clk_i(clk),
		.wb_rst_i(state == STATE_RESET),
		.wb_stb_i(state == STATE_REQUEST),
		.wb_we_i(1),
		.wb_adr_i(pwm_address),
		.wb_dat_i(
			pwm_address == 0 ? 2'b11 :
			pwm_address == 1 ? 2'b01 :
			pwm_address == 2 ? 2'b00 :
			0
		),
		.wb_stall_o(pwm_stall),
		.wb_ack_o(pwm_ack),
		.pwm({ led_r, led_g, led_b }),
	);

	// issue a request over wishbone
	always @(posedge clk) begin
		case (state)
		STATE_END: begin
			pwm_address <= pwm_address + 1;
			state <= pwm_ack ? (pwm_address < 3) : state;
		end
		STATE_WAIT_ACK: begin
			state <= state + pwm_ack;
		end
		default: begin
			state <= state + 1;
		end
		endcase
	end
endmodule
