`default_nettype none

module spi_tx (
  input  clk_sys_i,
  input  clk_spi_i,

  // spi peripheral, transmitter
  input  spi_csn_i,
  output spi_sd_o,

  // clock domain crossing
  input  [7:0] tx_data_i,
  input  tx_req_i
);
  logic dummy;
  logic [7:0] spi_shift_d, spi_shift_q;
  logic [7:0] spi_data_d, spi_data_q;
  logic [2:0] spi_cnt_q;

  assign spi_sd_o = spi_shift_q[7];

  always_ff @(posedge clk_spi_i) begin
    spi_cnt_q <= spi_cnt_q + 1;
    spi_shift_q <= spi_shift_d;
    spi_data_q <= spi_data_d;
  end

  logic [7:0] spi_cdc_data;
  logic spi_cdc_stb;

  always_comb begin
    spi_shift_d = spi_shift_q;
    spi_data_d = spi_data_q;

    if (spi_csn_i) begin
      spi_shift_d = {spi_shift_q[6:0], 1'b0};
      spi_data_d = spi_data_q;

      if (spi_cnt_q == 3'b111) begin
        spi_shift_d = spi_data_q;
      end

      if (spi_cdc_stb) begin
        spi_data_d = spi_cdc_data;
      end
    end
  end

  clock_domain_crossing cdc (
    .clk_src_i(clk_sys_i),
    .src_data_i(tx_data_i), .src_req_i(tx_req_i), .src_rdy_o(dummy),
    .clk_dst_i(clk_spi_i),
    .dst_data_o(spi_cdc_data), .dst_req_o(spi_cdc_stb)
  );

endmodule
