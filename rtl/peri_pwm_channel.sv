`default_nettype none

module mPwmChannel #(
  parameter ClkHz = 0,
  parameter PwmHz = 0
) (
  input logic clk_i,
  input logic rst_ni,
  output wb_dat_o,
  output wb_ack_o,
  input wb_we_i,
  input wb_adr_i,
  input wb_dat_i,
  input wb_stb_i,
  output logic pwm
);
  localparam TicksPerCycle = ClkHz / PwmHz;

  logic [8:0] cnt;
  logic [7:0] duty_cycle;

  assign pwm = { 1'b1, duty_cycle } > cnt;
  assign wb_ack = wb_stb;

  always_ff @(posedge clk_i) begin
    if (wb_stb) begin
      duty_cycle <= wb_dat;
    end

    cnt <= cnt + 1;
    if (cnt[8]) begin
      cnt <= 0;
    end

    if (!rst_ni) begin
      {cnt, duty_cycle} <= 0;
    end
  end

endmodule
