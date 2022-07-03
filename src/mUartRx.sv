`default_nettype none

// Simple sampling UART receiver with static baud rate

typedef enum {
	STATE_IDLE,
	STATE_START,
	STATE_BIT_0,
	STATE_BIT_1,
	STATE_BIT_2,
	STATE_BIT_3,
	STATE_BIT_4,
	STATE_BIT_5,
	STATE_BIT_6,
	STATE_BIT_7,
	STATE_STOP
} eUartRxState;

module mUartRx #(
	parameter TICKS_PER_BAUD = 0
) (
	input wire clk,
	input wire rst,
	input wire stb,
	output reg irq,
	output reg [7:0] data,
	input wire rx
);
	reg [3:0] state = 0;
	reg [$size(TICKS_PER_BAUD)-1:0] baud_cnt = 0;
	reg [7:0] shift_reg = 0;

	always_ff @(posedge clk) begin
		case (state)
		STATE_IDLE: begin
			if (rx == 0) begin
				state <= STATE_START;
				// 1 to compensate register delay
				baud_cnt <= (TICKS_PER_BAUD > 1) ? 1 : 0;
			end
		end
		default: begin
			baud_cnt <= baud_cnt + 1;

			if (baud_cnt == TICKS_PER_BAUD / 2)
				shift_reg <= { !rx, shift_reg[7:1] };

			if (baud_cnt == TICKS_PER_BAUD - 1) begin
				if (state == STATE_BIT_7) begin
					// continuously update the data buffer
					data <= shift_reg;
					// raise interrupt: dinner is served
					rx <= 1;
				end

				state <= (state == STATE_BIT_7) ? 0 : state + 1;
				baud_cnt <= 0;
			end
		end
		endcase

		if (stb)
			// TODO: What if we read the data register just now?
			// Should the IRQ be set for one clock and disappear?
			irq_rx <= 0;

		if (rst) begin
			{ state, shift_reg, baud_cnt, data } <= 0;
		end
	end

`ifdef FORMAL
	reg f_rst = 0;

	assert property (baud_cnt < TICKS_PER_BAUD);

	always_ff @(*) begin
		cover(rst);
	end

	always_ff @(posedge clk) begin
		if (rst)
			f_rst <= 1;
	end
`endif

endmodule
