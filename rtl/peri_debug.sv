`default_nettype none

module peri_debug (
  input  clk_i,
  input  rst_ni,

  // wishbone b4 peripheral
  input  wb_we_i,
  input  wb_stb_i,
  output wb_ack_o,
  input  [3:0] wb_adr_i,
  input  [7:0] wb_dat_i,
  output [7:0] wb_dat_o,

  // led i/o
  output [7:0] debug_o
);
  logic unused = |{wb_adr_i};
  logic [7:0] debug_d, debug_q;

  assign wb_dat_o = 0;
  assign wb_ack_o = wb_stb_i;
  assign debug_o = debug_d;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      debug_q <= 8'b11011011;
    end else begin
      debug_q <= debug_d;
    end
  end

  always_comb begin
    debug_d = debug_q;
    if (wb_stb_i) if (wb_we_i) debug_d = wb_dat_i;
  end

endmodule
