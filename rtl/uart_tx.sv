`default_nettype none
//
// Simple UART transmitter with config-time static baud rate
//
module uart_tx #(
  parameter TicksPerBaud = 0
) (
  input clk_i,
  input rst_ni,

  // data input
  input [7:0] tx_data_i,
  input tx_valid_i,

  // uart output
  output uart_tx_no
);
  typedef enum {
    StIdle,
    StBit0, StBit1, StBit2, StBit3, StBit4, StBit5, StBit6, StBit7,
    StStop
  } state_e;

  state_e state_d, state_q;
  logic [9:0] shift_d, shift_q;
  logic [$size(TicksPerBaud)-1:0] cnt_q, cnt_d;

  assign uart_tx_no = !shift_d[0];

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      state_q <= 0;
      shift_q <= 0;
      cnt_q <= 0;
    end else begin
      state_q <= state_d;
      shift_q <= shift_d;
      cnt_q <= cnt_d;
    end
  end

  always_comb begin
    case (state_q)

      StIdle: begin
        if (tx_valid_i) begin
          shift_d = {1'b0, tx_data_i[7:0], 1'b1};
          state_d <= StBit0;
        end
      end

      default: begin
        cnt_d = cnt_q + 1;

        if (cnt_d == TicksPerBaud) begin
          cnt_d = 0;
          state_d = state_q + 1;
          shift_d <= {1'b0, shift_q[9:1]};
          if (state_q == StStop) begin
            state_d = 0;
          end
        end
      end

    endcase
  end

endmodule
