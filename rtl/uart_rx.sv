`default_nettype none

// Simple sampling UART receiver with static baud rate

typedef enum {
  StIdle,
  StStart,
  StBit0, StBit1, StBit2, StBit3, StBit4, StBit5, StBit6, StBit7,
  StStop
} state_e;

module mUartRx #(
  parameter BaudRate = 0,
  parameter ClkHz = 0,
  localparam TicksPerBaud = ClkHz / BaudRate
) (
  input logic clk_i,
  input logic rst_ni,
  output logic stb,
  output logic [7:0] data,
  input logic rx
);
  state_e state;
  logic [$size(TicksPerBaud)-1:0] baud_cnt;
  logic [7:0] shifter;

  always_ff @(posedge clk_i) begin
    stb <= 0;

    case (state)
    eUartState_Idle: begin
      if (rx == 0) begin
        state <= eUartState_Start;
        // start at 1 to compensate register delay
        baud_cnt <= (TicksPerBaud > 1) ? 1 : 0;
      end
    end
    default: begin
      baud_cnt <= baud_cnt + 1;

      if (baud_cnt == TicksPerBaud / 2) begin
        shifter <= {!rx, shifter[7:1]};
      end

      if (baud_cnt == TicksPerBaud - 1) begin
        if (state == eUartState_Bit7) begin
          data <= shifter;
          stb <= 1;
        end
        state <= (state == eUartState_Bit7) ? 0 : state + 1;
        baud_cnt <= 0;
      end
    end
    endcase

    if (!rst_ni) begin
      {state, shifter, baud_cnt, data} <= 0;
    end
  end
endmodule
