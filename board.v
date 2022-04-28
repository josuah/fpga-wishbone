module board (
	// led
	output wire rgb0,
	output wire rgb1,
	output wire rgb2,

	// uart
	input wire gpio_10,
	output wire gpio_20,

	// charlie7x5
	output wire gpio_38,
	output wire gpio_36,
	output wire gpio_34,
	output wire gpio_31,
	output wire gpio_32,
	output wire gpio_26,
	output wire gpio_23,

	// pwm_servo
	output wire gpio_2
);
	wire clock;
	wire led_r, led_g, led_b;

	wire [6:0] charlie7x5_oe;
	wire [6:0] charlie7x5_o;

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
			gpio_38, gpio_36, gpio_34, gpio_31, gpio_32, gpio_26,
			gpio_23
		}),
		.LATCH_INPUT_VALUE(1'b0),
		.CLOCK_ENABLE(1'b0),
		.OUTPUT_ENABLE(charlie7x5_oe),
		.D_OUT_0(charlie7x5_o)
	);


	top #(
		.TICKS_PER_BAUD(48000000/9600)
	) top (
		.clock(clock),
		.uart_tx(gpio_10),
		.uart_rx(gpio_20),
		.led_r(led_r),
		.led_g(led_g),
		.led_b(led_b),
		.pwm_servo(gpio_2),
		.charlie7x5_oe(charlie7x5_oe),
		.charlie7x5_o(charlie7x5_o)
	);
endmodule
