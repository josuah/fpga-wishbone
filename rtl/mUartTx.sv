`default_nettype none

// Simple sampling UART transmitter with static baud rate

module mUartTx#(
	parameter pTicksPerBaud = 0
) (
	input	logic clk,
	input	logic rst,
	input	logic stb,
	input	logic[7:0] data,
	output	logic tx
);
	eUartState state;
	logic[9:0] shifter;
	logic[$size(pTicksPerBaud)-1:0] baud_cnt;

	assign tx = !shifter[0];

	always_ff @(posedge clk) begin
		case (state)
		eUartState_Idle: begin
			if (stb) begin
				shifter <= {1'b0, data[7:0], 1'b1};
				state <= eUartState_Start;
			end
		end
		default: begin
			baud_cnt <= baud_cnt + 1;

			if (baud_cnt == pTicksPerBaud - 1) begin
				state <= (state == eUartState_Stop) ? 0 : state + 1;
				shifter <= {1'b0, shifter[9:1]};
				baud_cnt <= 0;
			end
		end
		endcase

		if (rst) begin
			{state, shifter, baud_cnt} <= 0;
		end
	end
endmodule
