`default_nettype none

module peri_debug (
  input logic clk_i,
  input logic rst_ni,
  output iWishbone_Peri wb_p,
  input iWishbone_Ctrl wb_c,
  output logic [7:0] debug
);
  logic unused = |{ wb_adr };
  assign wb_dat = 0;
  assign wb_ack = wb_stb;

  always_ff @(posedge clk_i) begin
    if (wb_stb && wb_we) begin
      debug <= wb_dat;
    end

    if (!rst_ni) begin
      debug <= 8'b11011011;
    end
  end
endmodule
