`default_nettype none

// Simple sampling UART transmitter with static baud rate

typedef enum bit [3:0] {
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
} eUartTxState;

module mUartTx #(
	parameter TICKS_PER_BAUD = 0
) (
	input logic clk,
	input logic rst,
	input logic stb,
	input logic [7:0] data,
	output logic tx
);
	eUartState state;
	reg [9:0] shift_reg;
	reg [$size(TICKS_PER_BAUD)-1:0] baud_cnt;

	assign tx = !shift_reg[0];

	always_ff @(posedge clk) begin
		case (state)
		STATE_IDLE: begin
			if (stb) begin
				shift_reg <= { 1'b0, data[7:0], 1'b1 };
				state <= STATE_START;
			end
		end
		default: begin
			baud_cnt <= baud_cnt + 1;

			if (baud_cnt == TICKS_PER_BAUD - 1) begin
				state <= (state == STATE_STOP) ? 0 : state + 1;
				shift_reg <= { 1'b0, shift_reg[9:1] };
				baud_cnt <= 0;
			end
		end
		endcase

		if (rst)
			{ state, shift_reg, baud_cnt } <= 0;
	end

`ifdef FORMAL
	reg f_rst_done = 0;

	always_ff @(*) begin
		cover(rst);
		if (rst)
			f_rst_done <= 1;
	end

	always_ff @(*) begin
		if (f_rst_done) begin
			assert(state <= STATE_STOP);
			assert(baud_cnt < TICKS_PER_BAUD);

			case (state)
			STATE_IDLE: begin
				assert(baud_cnt == 0);
				assert(shift_reg == 0);
			end
			STATE_START: begin
				cover(baud_cnt == 0);
				cover(baud_cnt == 1);
				cover(baud_cnt == TICKS_PER_BAUD - 1);
			end
			default: begin
				assert(state > STATE_START);
				assert(state < STATE_STOP);
			end
			STATE_STOP: begin
				assert(shift_reg == 0);
			end
			endcase
		end
	end
`endif

endmodule
