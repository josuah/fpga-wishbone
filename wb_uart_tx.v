module wb_uart_tx #(
	parameter TICKS_PER_BAUD = 8
) (
	// Wishbone B4 (subset)
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire wb_stb_i,
	input wire [7:0] wb_dat_i,

	// UART
	output wire uart_tx
);
	localparam [3:0]
		STATE_IDLE	= 0,
		STATE_START	= 1,
		STATE_BIT_0	= 2,
		STATE_BIT_1	= 3,
		STATE_BIT_2	= 4,
		STATE_BIT_3	= 5,
		STATE_BIT_4	= 6,
		STATE_BIT_5	= 7,
		STATE_BIT_6	= 8,
		STATE_BIT_7	= 9,
		STATE_STOP	= 10,
		STATE_LAST	= 10;  // same as STATE_STOP

	reg [3:0] state = 0;
	reg [9:0] shift_reg = 0;
	reg [7:0] baud_cnt = 0;

	assign uart_tx = !shift_reg[0];

	always @(posedge wb_clk_i) begin
		if (state == STATE_IDLE) begin
			if (wb_stb_i) begin
				shift_reg <= { 1'b0, wb_dat_i[7:0], 1'b1 };
				state <= STATE_START;
			end
		end else begin
			baud_cnt <= baud_cnt + 1;

			if (baud_cnt == TICKS_PER_BAUD - 1) begin
				state <= (state == STATE_LAST) ? 0 : state + 1;
				shift_reg <= { 1'b0, shift_reg[9:1] };
				baud_cnt <= 0;
			end
		end

		if (wb_rst_i)
			{ state, shift_reg, baud_cnt } <= 0;
	end

`ifdef FORMAL
	reg f_rst_done = 0;

	always @(*) begin
		cover(wb_rst_i);
		if (wb_rst_i)
			f_rst_done <= 1;
	end

	always @(*) if (f_rst_done) begin
		assert(state <= STATE_LAST);
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
`endif

endmodule
