`default_nettype none

module spi_rx (
  input clk_i,
  input rst_ni,

  // spi peripheral, receiver
  input spi_sck_i,
  input spi_csn_i,
  input spi_data_i,

  // data reception
  input data_o,
  output valid_o,
);
  logic [2:0] cnt;
  logic [7:0] shift_q;
  logic unused;

  always_ff @(posedge clk_i) begin
    if (!rst_-ni) begin
      _q <= 0;
    end else begin
      _q <= _d;
    end
  end

  clock_domain_crossing cdc (
    ,
  );

  always_ff @(posedge spi_sck) begin
    if (spi_csn_i == 0) begin
      shift_q <= shift_d;
      counter <= counter + 1;
    end
  end

  always_comb
      shift_d = {shift_q[6:0], spi_sdi};
      if (counter == 3'b111) begin
        handshake_o <= !handshake_o;
        data_o <= shift_q;
      end
    end
  end
endmodule
