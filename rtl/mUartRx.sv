`default_nettype none
`include "rtl/eUartState.svh"

// Simple sampling UART receiver with static baud rate

module mUartRx #(
  parameter pBaudRate = 0,
  parameter pClkHz = 0,
  localparam pTicksPerBaud = pClkHz / pBaudRate
)(
  input logic clk,
  input logic rst,
  output logic stb,
  output logic [7:0] data,
  input logic rx
);
  eUartState state;
  logic [$size (pTicksPerBaud)-1:0] baud_cnt;
  logic [7:0] shifter;

  always_ff @(posedge clk) begin
    stb <= 0;

    case (state)
    eUartState_Idle: begin
      if (rx == 0) begin
        state <= eUartState_Start;
        // start at 1 to compensate register delay
        baud_cnt <= (pTicksPerBaud > 1) ? 1 : 0;
      end
    end
    default: begin
      baud_cnt <= baud_cnt + 1;

      if (baud_cnt == pTicksPerBaud / 2) begin
        shifter <= {!rx, shifter[7:1]};
      end

      if (baud_cnt == pTicksPerBaud - 1) begin
        if (state == eUartState_Bit7) begin
          data <= shifter;
          stb <= 1;
        end
        state <= (state == eUartState_Bit7) ? 0 : state + 1;
        baud_cnt <= 0;
      end
    end
    endcase

    if (rst) begin
      {state, shifter, baud_cnt, data} <= 0;
    end
  end
endmodule
