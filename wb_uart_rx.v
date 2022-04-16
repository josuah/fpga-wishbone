module wb_uart_rx #(
	parameter TICKS_PER_BAUD = 8
) (
	// Wishbone B4
	input wire i_wb_clk,
	input wire i_wb_rst,
	input wire i_wb_stb,
	output reg [7:0] o_wb_data,
	output reg o_wb_stall,
	output wire o_wb_ack,

	// UART
	input wire i_uart_rx
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
		STATE_BIT_LAST	= 9,  // same as STATE_BIT_7
		STATE_STOP	= 10,
		STATE_LAST	= 10;  // same as STATE_STOP

	reg [3:0] state = 0;
	reg [7:0] baud_cnt = 0;
	reg [7:0] shift_reg = 0;

	assign o_wb_ack = i_wb_stb && !o_wb_stall;

	always @(posedge i_wb_clk) begin
		if (i_wb_stb)
			o_wb_stall <= 1;  // data was picked up

		if (state == STATE_IDLE) begin
			if (i_uart_rx == 0) begin
				state <= STATE_START;
				// 1 to compensate register delay
				baud_cnt <= (TICKS_PER_BAUD > 1) ? 1 : 0;
			end
		end else begin
			baud_cnt <= baud_cnt + 1;

			if (baud_cnt == TICKS_PER_BAUD / 2)
				shift_reg <= { !i_uart_rx, shift_reg[7:1] };

			if (baud_cnt == TICKS_PER_BAUD - 1) begin
				if (state == STATE_BIT_LAST) begin
					// continuously update the data buffer
					o_wb_data <= shift_reg;
					o_wb_stall <= 0;  // data ready for pickup
				end

				state <= (state == STATE_LAST) ? 0 : state + 1;
				baud_cnt <= 0;
			end
		end

		if (i_wb_rst) begin
			{ state, shift_reg, baud_cnt, o_wb_data } <= 0;
			o_wb_stall <= 1;
		end
	end

`ifdef FORMAL
	reg f_rst_done = 0;

	assert property (baud_cnt < TICKS_PER_BAUD);

	always @(*) begin
		cover(i_wb_rst);
		if (i_wb_rst)
			f_rst_done <= 1;
	end
`endif

endmodule
