module board (
	output wire rgb0,
	output wire rgb1,
	output wire rgb2,
	output wire gpio_26,
	output wire gpio_27
);
	wire clk;
	wire [32+32+1-1:0] unused = { o_wb_data, o_wb_stall, o_wb_ack };
	wire led_r, led_g, led_b;

	reg [2:0] state = 0;

	assign gpio_26 = 0;
	assign gpio_27 = 0;

	localparam [2:0]
		STATE_RESET = 0,
		STATE_READY = 1,
		STATE_REQUEST = 2,
		STATE_END = 3;

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
	wb_led_pwm wb_led_pwm (
		// Wishbone B4
		.i_wb_clk(clk),
		.i_wb_rst(state == STATE_RESET),
		.i_wb_cyc(state == STATE_REQUEST),
		.i_wb_stb(state == STATE_REQUEST),
		.i_wb_we(1),
		.i_wb_addr(0),
		.i_wb_data(32'h110000),
		.o_wb_data(o_wb_data),
		.o_wb_stall(o_wb_stall),
		.o_wb_ack(o_wb_ack),
		.o_led_r(led_r),
		.o_led_g(led_g),
		.o_led_b(led_b)
	);

	/* issue a request over wishbone */
	always @(posedge clk) begin
		if (state < STATE_END)
			state <= state + 1;
	end
endmodule
