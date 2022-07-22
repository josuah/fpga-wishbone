`default_nettype none

module synthesis (
  input logic gpio_spi_sck,
  input logic gpio_spi_csn,
  input logic gpio_spi_sdi,
  output logic gpio_spi_sdo,
  output logic gpio_led_r,
  output logic gpio_led_g,
  output logic gpio_led_b,
  output logic [6:0] gpio_charlieplex,
  output logic [7:0] gpio_debug
);
  logic clk_i;
  logic [6:0] charlieplex_en_o;
  logic [6:0] charlieplex_o;

  SB_HFOSC hfosc (
    .CLKHFPU(1'b1),
    .CLKHFEN(1'b1),
    .CLKHF(clk_i)
  );

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

  SB_IO #(
    .PIN_TYPE({4'b1010, 2'b01}),
    .PULLUP(0),
    .NEG_TRIGGER(0),
    .IO_STANDARD("SB_LVCMOS")
  ) io_charlieplex (
    .PACKAGE_PIN(gpio_charlieplex),
    .LATCH_INPUT_VALUE(1'b0),
    .CLOCK_ENABLE(1'b0),
    .OUTPUT_ENABLE(charlieplex_en_o),
    .D_OUT_0(charlieplex_o)
  );

  top top (
    .clk_i,
    .spi_sck_i(gpio_spi_sck),
    .spi_csn_i(gpio_spi_csn),
    .spi_sd_i(gpio_spi_sdi),
    .spi_sd_o(gpio_spi_sdo),
    .led_r_o(led_r), .led_g_o(led_g), .led_b_o(led_b),
    .debug_o(gpio_debug),
    .charlieplex_en_o, .charlieplex_o
  );

endmodule
