module board (
	// led
	output wire rgb0,
	output wire rgb1,
	output wire rgb2,

	// uart
	input wire gpio_23,
	output wire gpio_25,

	// pwm_servo
	output wire gpio_26,

	// cxscreen
	output wire gpio_19,
	output wire gpio_11,
	output wire gpio_6,
	output wire gpio_4,
	output wire gpio_48,
	output wire gpio_47,
	output wire gpio_2
);
	wire clock;
	wire led_r, led_g, led_b;

	wire [6:0] cxscreen_oe;
	wire [6:0] cxscreen_o;

	// internal oscillator
	SB_HFOSC SB_HFOSC (
		.CLKHFPU(1'b1),
		.CLKHFEN(1'b1),
		.CLKHF(clock)
	);

	// RGB with voltage control
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

	// I/O Cell
	SB_IO #(
		.PIN_TYPE({ 4'b1010, 2'b01 }),
		.PULLUP(0),
		.NEG_TRIGGER(0),
		.IO_STANDARD("SB_LVCMOS")
	) SB_IO [6:0] (
		.PACKAGE_PIN({
			gpio_19, gpio_11, gpio_6, gpio_4, gpio_48, gpio_47,
			gpio_2
		}),
		.LATCH_INPUT_VALUE(1'b0),
		.CLOCK_ENABLE(1'b0),
		.OUTPUT_ENABLE(cxscreen_oe),
		.D_OUT_0(cxscreen_o)
	);


	top #(
		.TICKS_PER_BAUD(48000000/9600)
	) top (
		.clock(clock),
		.uart_tx(gpio_25),
		.uart_rx(gpio_23),
		.led_r(led_r),
		.led_g(led_g),
		.led_b(led_b),
		.pwm_servo(gpio_26),
		.cxscreen_oe(cxscreen_oe),
		.cxscreen_o(cxscreen_o)
	);
endmodule
