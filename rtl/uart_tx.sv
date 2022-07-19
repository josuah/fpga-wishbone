`default_nettype none

// Simple UART transmitter with config-time static baud rate

typedef enum {
  StIdle,
  StStart,
  StBit0, StBit1, StBit2, StBit3, StBit4, StBit5, StBit6, StBit7,
  StStop
} state_e;

module mUartTx #(
  parameter TicksPerBaud = 0
) (
  input logic clk_i,
  input logic rst_ni,
  input logic stb,
  input logic [7:0] data,
  output logic tx
);
  eUartState state;
  logic [9:0] shifter;
  logic [$size (TicksPerBaud)-1:0] baud_cnt;

  assign tx = !shifter[0];

  always_ff @(posedge clk_i) begin
    case (state)
    eUartState_Idle: begin
      if (stb) begin
        shifter <= {1'b0, data[7:0], 1'b1};
        state <= eUartState_Start;
      end
    end
    default: begin
      baud_cnt <= baud_cnt + 1;

      if (baud_cnt == TicksPerBaud - 1) begin
        state <= (state == eUartState_Stop) ? 0 : state + 1;
        shifter <= {1'b0, shifter[9:1]};
        baud_cnt <= 0;
      end
    end
    endcase

    if (!rst_ni) begin
      {state, shifter, baud_cnt} <= 0;
    end
  end
endmodule
