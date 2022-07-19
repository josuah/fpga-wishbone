`default_nettype none

module mSpiTx (
  output iSpi_Peri spi_p,
  input iSpi_Ctrl spi_c,
  output cdc_ack_o,
  input cdc_data_i,
  input cdc_ack_i
);
  logic [7:0] shifter;
  logic [2:0] cnt;
  logic [7:0] data;
  logic [7:0] data_buf;
  logic stb;
  logic unused = |{spi_dat};

  assign spi_dat = shifter[7];

  mClockDomainImporter mcdi (
    .rst_ni (0), .clk_i (spi_sck),
    .cd_i, .cd_e,
    .stb,
    .data
  );

  always_ff @(posedge spi_sck) begin
    if (stb) begin
      data_buf <= data;
    end
    if (spi_csn == 0) begin
      cnt <= cnt + 1;
      shifter <= {shifter[6:0], 1'b0};

      if (cnt == 0) begin
        shifter <= data_buf;
      end
    end
  end

endmodule
