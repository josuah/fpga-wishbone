`default_nettype none

module ice40 (
  input gpio_uart_rx,
  output gpio_uart_tx,
  output gpio_led_r,
  output gpio_led_g,
  output gpio_led_b,
  output [6:0] gpio_charlieplex,
  output [7:0] gpio_debug
);
  logic clk_i;

  SB_HFOSC hfosc (
    .CLKHFPU(1'b1),
    .CLKHFEN(1'b1),
    .CLKHF(clk_i)
  );

  logic rst_ni;

  always_ff @(posedge clk_i) begin
    rst_ni <= 1;
  end

  logic led_r, led_g, led_b;

  SB_RGBA_DRV #(
    .CURRENT_MODE ("0b1"),   /* half current */
    .RGB0_CURRENT ("0b000001"),  /* 4 mA */
    .RGB1_CURRENT ("0b000001"),  /* 4 mA */
    .RGB2_CURRENT ("0b000001") /* 4 mA */
  ) rgba_drv (
    .CURREN(1'b1),
    .RGBLEDEN(1'b1),
    .RGB0PWM(led_g),
    .RGB0(gpio_led_g),
    .RGB1PWM(led_b),
    .RGB1(gpio_led_b),
    .RGB2PWM(led_r),
    .RGB2(gpio_led_r)
  );

  logic [6:0] charlieplex_out_en_o;
  logic [6:0] charlieplex_o;

  SB_IO #(
    .PIN_TYPE({4'b1010, 2'b01}),
    .PULLUP(0),
    .NEG_TRIGGER(0),
    .IO_STANDARD("SB_LVCMOS")
  ) io_charlieplex (
    .PACKAGE_PIN(gpio_charlieplex),
    .LATCH_INPUT_VALUE(1'b0),
    .CLOCK_ENABLE(1'b0),
    .OUTPUT_ENABLE(charlieplex_out_en_o),
    .D_OUT_0(charlieplex_o)
  );

  top top (
    .clk_i, .rst_ni,
    .uart_rx_ni(gpio_uart_rx),
    .uart_tx_no(gpio_uart_tx),
    .led_r_o(led_r), .led_g_o(led_g), .led_b_o(led_b),
    .led_debug_o(gpio_debug),
    .charlieplex_out_en_o, .charlieplex_o
  );

endmodule
