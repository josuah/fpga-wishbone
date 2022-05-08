`default_nettype none

module wbs_uart_rx #(
	parameter TICKS_PER_BAUD = 0
) (
	// wishbone b4 (subset)
	input wire wbs_clk_i,
	input wire wbs_rst_i,
	input wire wbs_stb_i,
	output reg [7:0] wbs_dat_o,

	// interrupts
	output reg irq_uart_rx,

	// uart
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
	reg [$size(TICKS_PER_BAUD)-1:0] baud_cnt = 0;
	reg [7:0] shift_reg = 0;

	always @(posedge wbs_clk_i) begin
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
				if (state == STATE_BIT_LAST) begin
					// continuously update the data buffer
					wbs_dat_o <= shift_reg;
					// raise interrupt: dinner is served
					irq_uart_rx <= 1;
				end

				state <= (state == STATE_LAST) ? 0 : state + 1;
				baud_cnt <= 0;
			end
		end

		if (wbs_stb_i)
			irq_uart_rx <= 0;	// what if we read the data register just now? should be set for one clock and disappear?

		if (wbs_rst_i) begin
			{ state, shift_reg, baud_cnt, wbs_dat_o } <= 0;
		end
	end

`ifdef FORMAL
	reg f_rst = 0;

	assert property (baud_cnt < TICKS_PER_BAUD);

	always @(*) begin
		cover(wbs_rst_i);
		if (wbs_rst_i)
			f_rst <= 1;
	end
`endif

endmodule
