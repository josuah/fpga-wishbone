module simulation (
	// Wishbone B4
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire wb_stb_i,
	input wire wb_cyc_i,
	input wire wb_we_i,
	input wire [31:0] wb_adr_i,
	input wire [31:0] wb_dat_i,
	output wire wb_stall_o,
	output wire wb_ack_o,

	// PWM-controlled LEDs
	output wire led_r,
	output wire led_g,
	output wire led_b
);
	wb_pwm #(
		.BITS(5),
		.CHANNELS(3)
	) wb_pwm (
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_stb_i(wb_stb_i),
		.wb_cyc_i(wb_cyc_i),
		.wb_we_i(wb_we_i),
		.wb_adr_i(wb_adr_i),
		.wb_dat_i(wb_dat_i),
		.wb_stall_o(wb_stall_o),
		.wb_ack_o(wb_ack_o),
		.pwm({ led_b, led_g, led_r })
	);
endmodule
