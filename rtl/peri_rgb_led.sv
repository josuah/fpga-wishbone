`default_nettype none

module peri_rgb_led (
  input logic clk_i,
  input logic rst_ni,

  // wishbone b4 peripheral
  input wb_we_i,
  input [3:0] wb_adr_i,
  input [7:0] wb_dat_i,
  input wb_stb_i,
  output [7:0] wb_dat_o,
  output wb_ack_o,

  // pwm output
  output logic led_r_o,
  output logic led_g_o,
  output logic led_b_o
);
  logic [8:0] cnt_d, cnt_q;
  logic [7:0] pwm_r_d, pwm_r_q;
  logic [7:0] pwm_g_d, pwm_g_q;
  logic [7:0] pwm_b_d, pwm_b_q;

  assign wb_ack_o = wb_stb_i;
  assign wb_dat_o = 0;
  assign led_r_o = cnt_q < {1'b0, pwm_r_q};
  assign led_g_o = cnt_q < {1'b0, pwm_g_q};
  assign led_b_o = cnt_q < {1'b0, pwm_b_q};

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      cnt_q <= 0;
      pwm_r_q <= 0;
      pwm_g_q <= 0;
      pwm_b_q <= 0;
    end else begin
      cnt_q <= cnt_d;
      pwm_r_q <= pwm_r_d;
      pwm_g_q <= pwm_g_d;
      pwm_b_q <= pwm_b_d;
    end
  end

  always_comb begin
    cnt_d = cnt_q[8] ? 0 : cnt_q + 1;
    pwm_r_d = pwm_r_q;
    pwm_g_d = pwm_g_q;
    pwm_b_d = pwm_b_q;

    if (wb_stb_i && wb_we_i) begin
      case (wb_adr_i)
        4'h0: pwm_r_d = wb_dat_i;
        4'h1: pwm_g_d = wb_dat_i;
        4'h2: pwm_b_d = wb_dat_i;
        default: ;
      endcase
    end
  end

endmodule
