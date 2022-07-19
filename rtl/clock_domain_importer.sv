`default_nettype none

// This part imports a buffer of data from the other clock domain.
// As `data` becomes valid, `stb` rises for one clock.

module clock_domain_importer #(
  parameter Bits = 8
) (
  input logic clk_i,
  input logic rst_ni,

  // clock domain crossing
  output cdc_ack_o,
  input cdc_data_i,
  input cdc_ack_i
  output logic stb,
  output logic [Bits-1:0] data
);
  logic [1:0] req_q;

  assign data = cd_e.data;
  assign stb = (req_q[0] != cd_i.ack);

  always_ff @(posedge clk_i) begin
    // flip-flop buffer to prevent metastable state propagation
    req_q <= {cd_e.req, req_q[1]};

    // the `ack` signal follows the `req` signal
    cd_i.ack <= req_q[0];

    if (!rst_ni) begin
      {req_q, cd_i.ack} <= 0;
    end
  end
endmodule
