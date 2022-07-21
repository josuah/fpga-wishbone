`default_nettype none

module mPdmChannel #(
  parameter Bits = 0
) (
  input rst_ni,
  input clk_i,

  // wishbone b4 peripheral
  input wb_we_i,
  input wb_adr_i,
  input wb_dat_i,
  input wb_stb_i,
  output wb_dat_o,
  output wb_ack_o,

  // pdm channel
  output pdm
);
  logic [Bits-1:0] level_q, level_d;
  logic [Bits:0] accumulator;

  assign pdm = accumulator[Bits];
  assign wb_ack = wb_stb;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      level <= 0;
      accumulator <= 0;
    end else begin
      accumulator <= accumulator[Bits-1:0] + level;
    end
  end

  always_comb begin
      if (wb_stb_i) begin
        level <= wb_dat_i;
      end
    end
  end
endmodule
