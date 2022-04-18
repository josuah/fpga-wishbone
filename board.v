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
	reg [31:0] pwm_addr = 0;

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
		.PWM_CHANS(3),
		.PWM_BITS(3)
	) wb_pwm (
		.i_wb_clk(clk),
		.i_wb_rst(state == STATE_RESET),
		.i_wb_stb(state == STATE_REQUEST),
		.i_wb_we(1),
		.i_wb_addr(pwm_addr),
		.i_wb_data(
			pwm_addr == 0 ? 3'b111 :
			pwm_addr == 1 ? 3'b011 :
			pwm_addr == 2 ? 3'b001 :
			0
		),
		.o_wb_stall(pwm_stall),
		.o_wb_ack(pwm_ack),
		.o_pwm_chan({ led_r, led_g, led_b }),
	);

	// issue a request over wishbone
	always @(posedge clk) begin
		case (state)
		STATE_END: begin
			pwm_addr <= pwm_addr + 1;
			state <= pwm_ack ? (pwm_addr < 3) : state;
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
