`default_nettype none

module peri_mems_microphone #(
  parameter TicksPerHz = 2
) (
  input clk_i,
  input rst_ni,

  // wishbone b4 peripheral
  input wb_we_i,
  input wb_stb_i,
  output wb_ack_o,
  input [3:0] wb_adr_i,
  input [7:0] wb_dat_i,
  output [7:0] wb_dat_o,

  // microphone i/o
  output mic_clk_o,
  input mic_data_i,

  // interrupt
  output irq_o
);
  logic unused = |{wb_adr_i};
  logic [$clog2(TicksPerHz):0] mic_cnt_d, mic_cnt_q;
  logic [7:0] sample_buf_d, sample_buf_q;
  logic [7:0] sample_cnt_d, sample_cnt_q;
  logic [7:0] wb_dat_d, wb_dat_q;
  logic mic_clk_d, mic_clk_q;
  logic irq_d;
  assign wb_dat_o = wb_dat_d;
  assign wb_ack_o = wb_stb_i;
  assign mic_clk_o = mic_clk_d;
  assign irq_o = irq_d;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      mic_cnt_q <= 0;
      mic_clk_q <= 0;
      sample_buf_q <= 0;
      sample_cnt_q <= 0;
      wb_dat_q <= 0;
    end else begin
      mic_cnt_q <= mic_cnt_d;
      mic_clk_q <= mic_clk_d;
      sample_buf_q <= sample_buf_d;
      sample_cnt_q <= sample_cnt_d;
      wb_dat_q <= wb_dat_d;
    end
  end

  // divide the input clock
  always_comb begin
    mic_clk_d = mic_clk_q;
    mic_cnt_d = mic_cnt_q - 1;
    if (mic_cnt_q == 0) begin
      mic_cnt_d = TicksPerHz - 1;
      mic_clk_d = !mic_clk_q;
    end
  end

  // sample the mic data on `mic_clk_o` positive edge, 
  always_comb begin
    wb_dat_d = wb_dat_q;
    sample_buf_d = sample_buf_q;
    sample_cnt_d = sample_cnt_q;
    irq_d = 0;

    // synchronise with mic_clk_o pace
    if (mic_clk_q == 0 && mic_clk_d == 1) begin
      sample_cnt_d = sample_cnt_q + 1; // overflowing
      sample_buf_d = sample_buf_q + (mic_data_i ? 1 : 0);

      // reset the sample buffer on counter overflow
      if (sample_cnt_q == 0) begin
        wb_dat_d = sample_buf_d;
        irq_d = 1;

        // add the first value right away
        sample_buf_d = mic_data_i ? 1 : 0;
      end
    end
  end

endmodule
