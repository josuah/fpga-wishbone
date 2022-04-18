module wb_uart_rx #(
	parameter TICKS_PER_BAUD = 8
) (
	// Wishbone B4 (subset)
	input wire wb_clk_i,
	input wire wb_rst_i,
	output reg [7:0] wb_dat_o,

	// UART
	input wire uart_rx
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

	always @(posedge wb_clk_i) begin
		if (state == STATE_IDLE) begin
			if (uart_rx == 0) begin
				state <= STATE_START;
				// 1 to compensate register delay
				baud_cnt <= (TICKS_PER_BAUD > 1) ? 1 : 0;
			end
		end else begin
			baud_cnt <= baud_cnt + 1;

			if (baud_cnt == TICKS_PER_BAUD / 2)
				shift_reg <= { !uart_rx, shift_reg[7:1] };

			if (baud_cnt == TICKS_PER_BAUD - 1) begin
				if (state == STATE_BIT_LAST)
					// continuously update the data buffer
					wb_dat_o <= shift_reg;

				state <= (state == STATE_LAST) ? 0 : state + 1;
				baud_cnt <= 0;
			end
		end

		if (wb_rst_i) begin
			{ state, shift_reg, baud_cnt, wb_dat_o } <= 0;
		end
	end

`ifdef FORMAL
	reg f_rst = 0;

	assert property (baud_cnt < TICKS_PER_BAUD);

	always @(*) begin
		cover(wb_rst_i);
		if (wb_rst_i)
			f_rst <= 1;
	end
`endif

endmodule
