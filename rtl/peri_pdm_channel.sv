`default_nettype none

module mPdmChannel #(
  parameter Bits = 0
) (
  input logic rst_ni,
  input logic clk_i,
  input iWishbone_Peri wb_p,
  input iWishbone_Ctrl wb_c,
  output logic pdm
);
  logic [Bits-1:0] level;
  logic [Bits:0] accumulator;

  assign pdm = accumulator[Bits];
  assign wb_ack = wb_stb;

  always_ff @(posedge clk_i) begin
    accumulator <= accumulator[Bits-1:0] + level;

    if (wb_stb) begin
      level <= wb_dat;
    end

    if (!rst_ni) begin
      {level, accumulator} <= 0;
    end
  end
endmodule
