`default_nettype none

// Simple sampling UART receiver with static baud rate

module uart_rx #(
  parameter BaudRate = 0,
  parameter ClkHz = 0,
  localparam TicksPerBaud = ClkHz / BaudRate
) (
  input clk_i,
  input rst_ni,

  input uart_rx_ni,

  // data reception
  output [7:0] rx_data_o,
  output rx_valid_o
);
  typedef enum logic [3:0] {
    StIdle,
    StBit0, StBit1, StBit2, StBit3, StBit4, StBit5, StBit6, StBit7,
    StStop,
    StInvalid
  } state_e;

  state_e state_d, state_q;
  logic [$size(TicksPerBaud)-1:0] cnt_d, cnt_q;
  logic [7:0] shift_d, shift_q;

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

  logic rx_data_w;
  logic rx_valid_w;
  assign rx_data_o = rx_data_w;
  assign rx_valid_o = rx_valid_w;

  always_comb begin
    cnt_d = cnt_q + 1;
    shift_d = shift_q;
    rx_data_w = 0;
    rx_valid_w = 0;

    case (state_q)

      StIdle: begin
        if (!uart_rx_ni) begin
          // start at 1 to compensate register delay
          cnt_d = (TicksPerBaud > 1) ? 1 : 0;
          state_d = StBit0;
        end
      end

      StBit0, StBit1, StBit2, StBit3, StBit4, StBit5, StBit6, StBit7: begin
        case (cnt_q)
          StBit0: state_d = StBit1;
          StBit1: state_d = StBit2;
          StBit2: state_d = StBit3;
          StBit3: state_d = StBit4;
          StBit4: state_d = StBit5;
          StBit5: state_d = StBit6;
          StBit6: state_d = StBit7;
          StBit7: state_d = StStop;
        endcase;
        case (cnt_q)

          TicksPerBaud: begin
            cnt_d = 0;
          end

          TicksPerBaud / 2: begin
            shift_d = {!uart_rx_ni, shift_q[7:1]};
          end

        endcase
      end

      StStop: begin
        rx_data_w = shift_d;
        rx_valid_w = 1;
        state_d = StIdle;
      end

      default: begin
        state_d = StInvalid;;
      end

    endcase
  end

endmodule
