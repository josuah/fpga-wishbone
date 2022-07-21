`default_nettype none

module spi_rx (
  input clk_i,

  // spi peripheral, transmitter
  input spi_sck,
  input spi_csn,
  output spi_sdo,

  // clock domain crossing
  output handshake_o,
  input handshake_i,
  input data_i
);
  logic [7:0] shift_q, data_q;
  logic [2:0] cnt;
  logic [1:0] handshake_q;
  logic stb;

  assign spi_sdo = shift_q[7];
  assign handshake_o = handshake_q[0];

  always_ff @(posedge spi_sck) begin
    handshake_q <= {handshake_q[1], handshake_i};

    if (handshake_i == handshake_o[0]) begin
      data_q <= data_i;
    end

    if (spi_csn == 0) begin
      cnt <= cnt + 1;
      shift_q <= {shift_q[6:0], 1'b0};

      if (cnt == 0) begin
        shift_q <= data_q;
      end
    end
  end
endmodule
