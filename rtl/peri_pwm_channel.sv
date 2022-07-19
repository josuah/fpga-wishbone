`default_nettype none

module mPwmChannel #(
  parameter ClkHz = 0,
  parameter PwmHz = 0
) (
  input logic clk_i,
  input logic rst_ni,
  output iWishbone_Peri wb_p,
  input iWishbone_Ctrl wb_c,
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
