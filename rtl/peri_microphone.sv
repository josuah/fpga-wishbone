`default_nettype none

module peri_mems_microphone #(
  parameter ClkHz = 0,
  parameter MicHz = 3000000,
  parameter AudioBits = 16
) (
  input clk_i,
  output rst_ni,

  // wishbone b4 peripheral
  output wb_dat_o,
  output wb_ack_o,
  input wb_we_i,
  input wb_adr_i,
  input wb_dat_i,
  input wb_stb_i,

  // microphone i/o
  output mic_clk_o,
  input mic_data,

  // interrupt
  output irq
);
  localparam TicksPerHz = ClkHz / MicHz / 2;

  logic [$clog2(TicksPerHz)-1:0] mic_clk_div;
  logic [AudioBits-1:0] sampling_buf, sampling_cnt;

  assign wb_ack_i = wb_stb_i;

  assign mic_clk_o = mic_clk_q;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      mic_clk_div_q <= 0;
      mic_clk_q <= 0;
    end else begin
      mic_clk_div_q <= mic_clk_div_d;
      mic_clk_q <= mic_clk_d;
    end
  end

  always_comb begin

    // divide the input clock
    mic_clc_div_q <= mic_clk_div_q + 1;
    if (mic_clk_div_q == TicksPerHz) begin
      mic_clk_div_d = 0;
      mic_clk_d = !mic_clk_q;
    end

    irq = 0;
    if (mic_clk_div == 0 && clk_i == 1) begin
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
      {mic_clk_o, mic_clk_div, sampling_buf, sampling_cnt} <= 0;
    end
  end
endmodule
