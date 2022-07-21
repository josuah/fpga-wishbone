`default_nettype none

module peri_blinkenlight #(
  parameter Leds = 8
) (
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
  output [Leds-1:0] blinkenlights_o
);
  logic [3:0] counter_q;
  logic request, we, dat_p, dat_c;

  assign blinkenlights_o = {counter_q, request, we, dat_c, dat_p};

  always_ff @(posedge clk_i) begin

    if (wb_stb) begin
      dat_c <= |wb_dat;
      dat_p <= 0;
      request <= 1;
    end

    if (wb_ack) begin
      dat_p <= |wb_dat;
      dat_c <= 0;
      request <= 1;
    end

    if (wb_stb || wb_ack) begin
      we <= wb_we;
      counter <= counter + 1;
    end

    if (!rst_ni) begin
      counter <= 4'b1111;
      request <= 1'b1; 
      {we, dat_p, dat_c} <= 0;
    end

  end
endmodule
