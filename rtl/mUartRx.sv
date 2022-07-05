// Simple sampling UART receiver with static baud rate

module mUartRx#(
	parameter TICKS_PER_BAUD = 0
) (
	input logic clk,
	input logic rst,
	input logic stb,
	output logic irq,
	output logic[7:0] data,
	input logic rx
);
	logic[3:0] state;
	logic[$size(TICKS_PER_BAUD)-1:0] baud_cnt;
	logic[7:0] shift;

	always_ff @(posedge clk) begin
		case (state)
		eUartState_Idle: begin
			if (rx == 0) begin
				state <= eUartState_Start;
				// 1 to compensate register delay
				baud_cnt <= (TICKS_PER_BAUD > 1) ? 1 : 0;
			end
		end
		default: begin
			baud_cnt <= baud_cnt + 1;

			if (baud_cnt == TICKS_PER_BAUD / 2)
				shift_logic <= { !rx, shifter[7:1] };

			if (baud_cnt == TICKS_PER_BAUD - 1) begin
				if (state == eUartState_Bit_7) begin
					// continuously update the data buffer
					data <= shifter;
					// raise interrupt: dinner is served
					rx <= 1;
				end

				state <= (state == eUartState_Bit_7) ? 0 : state + 1;
				baud_cnt <= 0;
			end
		end
		endcase

		if (stb)
			// TODO: What if we read the data register just now?
			// Should the IRQ be set for one clock and disappear?
			irq <= 0;

		if (rst) begin
			{ state, shifter, baud_cnt, data } <= 0;
		end
	end

`ifdef FORMAL
	logic f_rst = 0;

	assert property (baud_cnt < TICKS_PER_BAUD);

	always_comb begin
		cover(rst);
	end

	always_ff @(posedge clk) begin
		if (rst) begin
			f_rst <= 1;
		end
	end
`endif

endmodule
