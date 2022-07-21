`default_nettype none

module peri_debug (
  input clk_i,
  input rst_ni,

  // wishbone b4 peripheral
  input wb_we_i,
  input wb_adr_i,
  input wb_dat_i,
  input wb_stb_i,
  output wb_dat_o,
  output wb_ack_o,

  // led i/o
  output [7:0] debug_o
);
  logic unused = wb_adr_i;

  assign wb_dat_o = 0;
  assign wb_ack_o = wb_stb_i;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      debug_o <= 8'b11011011;
    end else begin

      if (wb_stb_i && wb_we_i) begin
        debug_o <= wb_dat_i;
      end
    end
  end

  always_comb begin

  end
endmodule
