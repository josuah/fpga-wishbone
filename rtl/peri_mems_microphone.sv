`default_nettype none

module peri_mems_microphone #(
  parameter ClkHz = 48_000_000,
  parameter MicHz = 3_000_000
) (
  input clk_i,
  output rst_ni,

  // wishbone b4 peripheral
  input wb_we_i,
  input wb_adr_i,
  input [7:0] wb_dat_i,
  input wb_stb_i,
  output [7:0] wb_dat_o,
  output wb_ack_o,

  // microphone i/o
  output mic_clk_o,
  input mic_data_i,

  // interrupt
  output irq_o
);
  localparam TicksPerHz = 8'(ClkHz / MicHz / 2);

  logic [$size(TicksPerHz)-1:0] mic_cnt_d, mic_cnt_q;
  logic [7:0] sample_buf_d, sample_buf_q;
  logic [$clog2(8)-1:0] sample_cnt_d, sample_cnt_q;
  logic [7:0] wb_dat_d, wb_dat_q;
  logic mic_clk_d, mic_clk_q;
  logic irq_w;
  assign wb_dat_o = wb_dat_d;
  assign wb_ack_o = wb_stb_i;
  assign mic_clk_o = mic_clk_d;
  assign irq_o = irq_w;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      mic_cnt_q <= TicksPerHz;
      mic_clk_q <= 0;
      sample_buf_q <= 0;
      sample_cnt_q <= 0;
      wb_dat_q <= 0;
    end else begin
      mic_cnt_q <= mic_cnt_q - 1;
      mic_clk_q <= mic_clk_d;
      sample_buf_q <= sample_buf_d;
      sample_cnt_q <= sample_cnt_q + 1;
      wb_dat_q <= wb_dat_d;
    end
  end

  // divide the input clock
  always_comb begin
    mic_clk_d = mic_clk_q;
    mic_cnt_d = mic_cnt_q;
    if (mic_cnt_q == 0) begin
      mic_cnt_d = TicksPerHz;
      mic_clk_d = !mic_clk_q;
    end
  end

  // sample the mic data on `mic_clk_o` positive edge, 
  logic mic_en;
  assign mic_en = (mic_cnt_q == 0 && mic_clk_o == 1);
  always_comb begin
    sample_buf_d = sample_buf_q;
    sample_cnt_d = sample_cnt_q;
    wb_dat_d = wb_dat_q;
    irq_w = 0;

    // apply the clock divider
    if (mic_en) begin
      sample_buf_d = sample_buf_q + (mic_data_i ? 1 : 0);

      // reset the sample buffer on counter overflow
      if (sample_cnt_q == 0) begin
        wb_dat_d = sample_buf_d;
        irq_w = 1;

        // add the first value right away
        sample_buf_d = mic_data_i ? 1 : 0;

        // and therefore not starting at zero
        sample_cnt_d = 1;
      end
    end
  end

endmodule
