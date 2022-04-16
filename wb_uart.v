module wb_uart #(
	parameter WB_ADDR_BITS = 32,
	parameter TICKS_PER_BAUD = 8
) (
	// Wishbone B4
	input wire i_wb_clk,
	input wire i_wb_rst,
	input wire i_wb_cyc,
	input wire i_wb_stb,
	input wire i_wb_we,
	input wire [WB_ADDR_BITS-1:0] i_wb_addr,
	input wire [31:0] i_wb_data,
	output wire [31:0] o_wb_data,
	output wire o_wb_stall,
	output wire o_wb_ack,

	// UART
	input wire i_uart_rx,
	output wire o_uart_tx
);
	wire [WB_ADDR_BITS+24-1:0] unused = {
		i_wb_addr[WB_ADDR_BITS-1:0],
		i_wb_data[31:8]
	};
	wire tx_stall, tx_ack;
	wire rx_stall, rx_ack;

	assign o_wb_ack = (tx_ack || rx_ack);
	assign o_wb_stall = i_wb_stb && (i_wb_we ? tx_stall : rx_stall);
	assign o_wb_data[31:8] = 0;

	wb_uart_tx #(
		.TICKS_PER_BAUD(TICKS_PER_BAUD)
	) wb_uart_tx (
		.i_wb_clk(i_wb_clk),
		.i_wb_rst(i_wb_rst),
		.i_wb_stb(i_wb_cyc && i_wb_stb && i_wb_we),
		.i_wb_data({ i_wb_data[7:0] }),
		.o_wb_stall(tx_stall),
		.o_wb_ack(tx_ack),
		.o_uart_tx(o_uart_tx)
	);

	wb_uart_rx #(
		.TICKS_PER_BAUD(TICKS_PER_BAUD)
	) wb_uart_rx (
		.i_wb_clk(i_wb_clk),
		.i_wb_rst(i_wb_rst),
		.i_wb_stb(i_wb_cyc && i_wb_stb && !i_wb_we),
		.o_wb_data(o_wb_data[7:0]),
		.o_wb_stall(rx_stall),
		.o_wb_ack(rx_ack),
		.i_uart_rx(i_uart_rx)
	);

endmodule
