`default_nettype none

module mSpiRx (
  // spi receiver
  input spi_sck,
  input spi_csn,
  input spi_sdi,

  // clock domain crossing
  output cdc_stb_o,
  output cdc_data_o,
  input cdc_ack_i
);
  logic [2:0] cnt;
  logic [7:0] shifter;
  logic unused;
  logic stb;

  mClockDomainExporter mcde (
    .rst_ni (0),
    .clk_i (spi_sck),
    .cd_e, .cd_i,
    .data (shifter),
    .stb,
    .ready (unused)
  );

  always_ff @(posedge spi_sck) begin
    stb <= 0;
    if (spi_csn == 0) begin
      if (spi_csn == 0) begin
        cnt <= cnt + 1;
        shifter <= {shifter[6:0], spi_dat};
      end
      if (cnt == 3'b111) begin
        stb <= 1;
      end
    end
  end
endmodule
