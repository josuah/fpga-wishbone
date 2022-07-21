`default_nettype none

module mRgbLed (
  input logic clk_i,
  input logic rst_ni,
  output wb_dat_o,
  output wb_ack_o,
  input wb_we_i,
  input wb_adr_i,
  input wb_dat_i,
  input wb_stb_i,
  output logic [2:0] rgb
);
  logic unused = |{wb_c};
  logic [2:0] cnt;
  logic [1:0] pwm_r;
  logic [1:0] pwm_g;
  logic [1:0] pwm_b;

  assign wb_ack = wb_stb;
  assign wb_dat = 0;
  assign rgb[0] = cnt < {1'b0, pwm_r};
  assign rgb[1] = cnt < {1'b0, pwm_g};
  assign rgb[2] = cnt < {1'b0, pwm_b};

  always_ff @(posedge clk_i) begin
    cnt <= cnt + 1;
    if (cnt[2]) begin
      cnt <= 0;
    end

    if (wb_stb) begin
      {pwm_r, pwm_g, pwm_b} <= wb_dat[5:0];
    end

    if (!rst_ni) begin
      {cnt, pwm_r, pwm_g, pwm_b} <= 0;
    end
  end
endmodule
