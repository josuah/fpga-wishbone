`default_nettype none
`include "rtl/iWishbone.svh"

module mPwmChannel #(
  parameter pClkHz = 0,
  parameter pPwmHz = 0
) (
  input logic clk,
  input logic rst,
  output iWishbone_Peri wb_p,
  input iWishbone_Ctrl wb_c,
  output logic pwm
);
  localparam pTicksPerCycle = pClkHz / pPwmHz;

  logic [8:0] cnt;
  logic [7:0] duty_cycle;

  assign pwm = { 1'b1, duty_cycle } > cnt;
  assign wb_p.ack = wb_c.stb;

  always_ff @(posedge clk) begin
    if (wb_c.stb) begin
      duty_cycle <= wb_c.dat;
    end

    cnt <= cnt + 1;
    if (cnt[8]) begin
      cnt <= 0;
    end

    if (rst) begin
      {cnt, duty_cycle} <= 0;
    end
  end

endmodule
