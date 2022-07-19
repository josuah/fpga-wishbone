`default_nettype none
`include "rtl/iClockDomain.svh"

// This part imports a buffer of data from the other clock domain.
// As `data` becomes valid, `stb` rises for one clock.

module mClockDomainImporter #(
  parameter pBits = 8
)(
  input logic clk,
  input logic rst,
  output  iClockDomain_Imp cd_i,
  input iClockDomain_Exp cd_e,
  output  logic stb,
  output  logic[pBits-1:0] data
);
  logic[1:0] req_ff;

  assign data = cd_e.data;
  assign stb = (req_ff[0] != cd_i.ack);

  always_ff @(posedge clk) begin
    // 2FF buffer to prevent metastable state propagation
    req_ff <= {cd_e.req, req_ff[1]};

    // the `ack` signal follows the `req` signal
    cd_i.ack <= req_ff[0];

    if (rst) begin
      {req_ff, cd_i.ack} <= 0;
    end
  end
endmodule
