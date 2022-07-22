`default_nettype none

module spi_rx (
  input clk_sys_i,
  input clk_spi_i,

  // spi peripheral, rx only
  input spi_csn_i,
  input spi_sd_i,

  // data output
  output [7:0] rx_data_o,
  output rx_valid_o
);
  logic unused;

  logic [2:0] spi_cnt_q, spi_cnt_d;
  logic [7:0] spi_shift_d, spi_shift_q;

  always_ff @(posedge clk_spi_i) begin
    spi_shift_q <= spi_shift_d;
    spi_data_q <= spi_data_d;
    spi_cnt_q <= spi_cnt_d;
  end

  // fill the shift queue with spi data input pin
  assign spi_shift_d = {spi_shift_q[6:0], spi_sd_i};

  logic [7:0] spi_data_d, spi_data_q;
  logic spi_valid;

  // on counter overflow, latch the spi data and make it cross clock domain
  always_comb begin
    spi_data_d = spi_data_q;
    spi_cnt_d = spi_cnt_q;
    spi_valid = 0;

    if (spi_csn_i) begin
      spi_cnt_d = spi_cnt_q + 1;

      if (spi_cnt_q == 3'b111) begin
        spi_data_d = spi_shift_q;
        spi_valid = 1;
      end
    end
  end

  clock_domain_crossing cdc (
    .clk_src_i(clk_sys_i),
    .src_data_i(spi_data_d), .src_valid_i(spi_valid), .src_ready_o(unused),
    .clk_dst_i(clk_spi_i),
    .dst_data_o(rx_data_o), .dst_valid_o(rx_valid_o)
  );

endmodule
