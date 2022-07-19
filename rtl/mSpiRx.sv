`default_nettype none
`include "rtl/iClockDomain.svh"
`include "rtl/iSpi.svh"

module mSpiRx (
  input iSpi_Ctrl spi_c,
  input iClockDomain_Imp cd_i,
  output iClockDomain_Exp cd_e
);
  logic [2:0] cnt;
  logic [7:0] shifter;
  logic unused;
  logic stb;

  mClockDomainExporter mcde (
    .rst (0),
    .clk (spi_c.sck),
    .cd_e, .cd_i,
    .data (shifter),
    .stb,
    .ready (unused)
  );

  always_ff @(posedge spi_c.sck) begin
    stb <= 0;
    if (spi_c.csn == 0) begin
      if (spi_c.csn == 0) begin
        cnt <= cnt + 1;
        shifter <= {shifter[6:0], spi_c.dat};
      end
      if (cnt == 3'b111) begin
        stb <= 1;
      end
    end
  end
endmodule
