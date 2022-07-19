`default_nettype none

module mBlinkenLight #(
  parameter Leds = 8
) (
  input logic clk_i,
  input logic rst_ni,
  input iWishbone_Ctrl wb_c,
  input iWishbone_Peri wb_p,
  output logic [Leds-1:0] blinkenlights
);
  logic [3:0] counter;
  logic request, we, dat_p, dat_c;

  assign blinkenlights = {counter, request, we, dat_c, dat_p};

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
