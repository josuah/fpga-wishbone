`default_nettype none

module mMicrophone #(
  parameter WbHz = 0,
  parameter MicHz = 3000000,
  parameter AudioBits = 16
) (
  input logic clk_i,
  output logic rst_ni,
  output iWishbone_Peri wb_p,
  input iWishbone_Ctrl wb_c,
  output logic mic_clk_i,
  input logic mic_data,
  output logic irq
);
  localparam TicksPerHz = WbHz / MicHz / 2;

  logic [$clog2(TicksPerHz)-1:0] mic_clk_i_cnt;
  logic [AudioBits-1:0] sampling_buf, sampling_cnt;

  assign wb_ack = wb_stb;

  always_ff @(posedge clk_i) begin

    // clock divider out to the microphone clock pin
    mic_clk_i_cnt <= mic_clk_i_cnt + 1;
    if (mic_clk_i_cnt == TicksPerHz) begin
      mic_clk_i_cnt <= 0;
      clk_i <= !clk_i;
    end

    irq = 0;
    if (mic_clk_i_cnt == 0 && clk_i == 1) begin
      sampling_buf <= sampling_buf + mic_data ? 1 : 0;
      sampling_cnt <= sampling_cnt + 1;

      // if next sampling would overflow
      if (sampling_cnt + 1 == 0) begin

        // continuously sampling wb_dat
        wb_dat <= sampling_buf;
        irq = 1;

        // not starting at zero because we add
        // the first_ni value right away
        sampling_cnt <= 1;
        sampling_buf <= mic_data ? 1 : 0;
      end
    end

    if (!rst_ni) begin
      {mic_clk_i, mic_clk_i_cnt, sampling_buf, sampling_cnt} <= 0;
    end
  end
endmodule
