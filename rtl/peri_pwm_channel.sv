`default_nettype none

module peri_pwm_channel (
  input clk_i,
  input rst_ni,

  // wishbone b4 peripheral
  input wb_we_i,
  input [3:0] wb_adr_i,
  input [7:0] wb_dat_i,
  input wb_stb_i,
  output [7:0] wb_dat_o,
  output wb_ack_o,

  // pwm output
  output logic pwm_o
);
  logic [7:0] duty_cycle_d, duty_cycle_q;
  logic [8:0] cnt_d, cnt_q;
  logic unused = &{wb_adr_i};

  assign wb_ack_o = wb_stb_i;
  assign wb_dat_o = 0;
  assign pwm_o = {1'b0, duty_cycle_d} > cnt_d;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      cnt_q <= 0;
      duty_cycle_q <= 0;
    end else begin
      cnt_q <= cnt_d;
      duty_cycle_q <= duty_cycle_d;
    end
  end

  assign cnt_d = cnt_q[8] ? 0 : cnt_q + 1;
  assign duty_cycle_d = (wb_stb_i && wb_we_i) ? wb_dat_i : duty_cycle_q;

endmodule
