`default_nettype none

// This part exports a buffer of data to the other clock domain.
// Rising `stb_i` for one clock queues `data_i` for transfer. To use
// only when ready.

module clock_domain_exporter #(
  parameter Bits = 8
) (
  input logic clk_i,
  input logic rst_ni,

  // clock domain crossing
  input cdc_ack_i,
  input cdc_data_i,
  input cdc_ack_o,

  // data i/o
  input logic stb_i,
  input logic [Bits-1:0] data_i,
  output logic ready_o
);
  logic [1:0] ack_q;

  assign ready = (ack_q[0] == cd_e.req);

  always_ff @(posedge clk_i) begin
    // flip-flop buffer to prevent metastable state propagation
    ack_q <= {cdc_ack_i, ack_q[1]};

    if (stb && ready) begin
      cd_e.data <= data;
      cd_e.req <= !cd_e.req;
    end

    if (!rst_ni) begin
      {ack_q, cd_e.data, cd_e.req} <= 0;
    end
  end
endmodule
