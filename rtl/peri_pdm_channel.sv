`default_nettype none

module peri_pdm_channel (
  input rst_ni,
  input clk_i,

  // wishbone b4 peripheral
  input wb_we_i,
  input wb_stb_i,
  output wb_ack_o,
  input [3:0] wb_adr_i,
  input [7:0] wb_dat_i,
  output [7:0] wb_dat_o,

  // pdm channel
  output pdm_o
);
  logic unused = |{wb_adr_i};
  logic [7:0] level_q, level_d;
  logic [8:0] accumulator_d, accumulator_q;

  assign wb_ack_o = wb_stb_i;
  assign wb_dat_o = 0;
  assign pdm_o = accumulator_q[8];

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      level_q <= 0;
      accumulator_q <= 0;
    end else begin
      level_q <= level_d;
      accumulator_q <= accumulator_d;
    end
  end

  assign accumulator_d = accumulator_q + {1'b0, level_d};
  assign level_d = (wb_stb_i && wb_we_i) ? wb_dat_i : level_q;

endmodule
