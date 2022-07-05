
// Simple sampling UART transmitter with static baud rate

module mUartTx #(
	parameter pTicksPerBaud = 0
) (
	input logic clk, rst, stb,
	input logic[7:0] data,
	output logic tx
);
	eUartState state;
	logic[9:0] shifter;
	logic[$size(pTicksPerBaud)-1:0] baud_cnt;

	assign tx = !shifter[0];

	always_ff @(posedge clk) begin
		case (state)
		STATE_IDLE: begin
			if (stb) begin
				shifter <= { 1'b0, data[7:0], 1'b1 };
				state <= STATE_START;
			end
		end
		default: begin
			baud_cnt <= baud_cnt + 1;

			if (baud_cnt == pTicksPerBaud - 1) begin
				state <= (state == STATE_STOP) ? 0 : state + 1;
				shifter <= { 1'b0, shifter[9:1] };
				baud_cnt <= 0;
			end
		end
		endcase

		if (rst)
			{ state, shifter, baud_cnt } <= 0;
	end

`ifdef FORMAL
	logic f_rst_done = 0;

	always_ff @(*) begin
		cover(rst);
		if (rst)
			f_rst_done <= 1;
	end

	always_ff @(*) begin
		if (f_rst_done) begin
			assert(state <= STATE_STOP);
			assert(baud_cnt < pTicksPerBaud);

			case (state)
			STATE_IDLE: begin
				assert(baud_cnt == 0);
				assert(shifter == 0);
			end
			STATE_START: begin
				cover(baud_cnt == 0);
				cover(baud_cnt == 1);
				cover(baud_cnt == pTicksPerBaud - 1);
			end
			default: begin
				assert(state > STATE_START);
				assert(state < STATE_STOP);
			end
			STATE_STOP: begin
				assert(shifter == 0);
			end
			endcase
		end
	end
`endif

endmodule
