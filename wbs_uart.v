`default_nettype none

module wbs_uart #(
	parameter WB_CLK_HZ = 0,
	parameter OUTPUT_HZ = 9600
) (
	// wishbone b4 (5.3)
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire wb_cyc_i,
	input wire wb_stb_i,
	input wire wb_we_i,
	input wire [3:0] wb_adr_i,
	input wire [31:0] wb_dat_i,
	output wire [31:0] wb_dat_o,
	output reg wb_ack_o,
	output wire wb_stall_o,

	// interrupts
	output irq_uart_rx,

	// uart
	input wire uart_rx,
	output wire uart_tx
);
	localparam TICKS_PER_BAUD = WB_CLK_HZ / OUTPUT_HZ;

	wire unused = &{ wb_dat_i[31:8], wb_dat_o[31:8], wb_adr_i };

	assign wb_dat_o[31:8] = 0;
	assign wb_stall_o = 0;

	wbs_uart_rx #(
		.TICKS_PER_BAUD(TICKS_PER_BAUD)
	) rx (
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_stb_i(wb_stb_i & !wb_we_i),
		.wb_dat_o(wb_dat_o[7:0]),
		.irq_uart_rx(irq_uart_rx),
		.uart_rx(uart_rx)
	);

	wbs_uart_tx #(
		.TICKS_PER_BAUD(TICKS_PER_BAUD)
	) tx (
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_stb_i(wb_stb_i & wb_we_i),
		.wb_dat_i(wb_dat_i[7:0]),
		.uart_tx(uart_tx)
	);

	always @(posedge wb_clk_i) begin
		wb_ack_o <= wb_cyc_i && wb_stb_i;
	end

endmodule
