module simulation #(
	parameter TICKS_PER_BAUD = 3
) (
`ifdef VERILATOR
	// Cosimulator
	output wire [31:0] o_uart_setup,
	input wire i_uart_sampling,
	input wire [7:0] i_uart_ticks_cnt,
`endif

	// Wishbone B4 bus
	input wire i_wb_clk,
	input wire i_wb_rst,
	input wire i_wb_cyc,
	input wire i_wb_stb,
	input wire i_wb_we,
	input wire [31:0] i_wb_addr,
	input wire [31:0] i_wb_data,
	output wire [31:0] o_wb_data,
	output wire o_wb_stall,
	output wire o_wb_ack
);
	wire [8:0] unused = { i_uart_sampling, i_uart_ticks_cnt };
	wire uart_io;

	wb_uart #(
		.TICKS_PER_BAUD(TICKS_PER_BAUD)
	) wb_uart (
		.i_wb_clk(i_wb_clk),
		.i_wb_rst(i_wb_rst),
		.i_wb_cyc(i_wb_cyc),
		.i_wb_stb(i_wb_stb),
		.i_wb_we(i_wb_we),
		.i_wb_addr(i_wb_addr),
		.i_wb_data(i_wb_data),
		.o_wb_data(o_wb_data),
		.o_wb_stall(o_wb_stall),
		.o_wb_ack(o_wb_ack),
		/* loop input back to output */
		.i_uart_rx(uart_io),
		.o_uart_tx(uart_io)
	);

	assign o_uart_setup = TICKS_PER_BAUD;
endmodule
