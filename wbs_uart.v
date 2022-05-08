`default_nettype none

module wbs_uart #(
	parameter WB_CLK_HZ = 0,
	parameter OUTPUT_HZ = 9600
) (
	// wishbone b4 (5.3)
	input wire wbs_clk_i,
	input wire wbs_rst_i,
	input wire wbs_cyc_i,
	input wire wbs_stb_i,
	input wire wbs_we_i,
	input wire [3:0] wbs_adr_i,
	input wire [31:0] wbs_dat_i,
	output wire [31:0] wbs_dat_o,
	output reg wbs_ack_o,
	output wire wbs_stall_o,

	// interrupts
	output irq_uart_rx,

	// uart
	input wire uart_rx,
	output wire uart_tx
);
	localparam TICKS_PER_BAUD = WB_CLK_HZ / OUTPUT_HZ;

	wire unused = &{ wbs_dat_i[31:8], wbs_dat_o[31:8], wbs_adr_i };

	assign wbs_dat_o[31:8] = 0;
	assign wbs_stall_o = 0;

	wbs_uart_rx #(
		.TICKS_PER_BAUD(TICKS_PER_BAUD)
	) rx (
		.wbs_clk_i(wbs_clk_i),
		.wbs_rst_i(wbs_rst_i),
		.wbs_stb_i(wbs_stb_i & !wbs_we_i),
		.wbs_dat_o(wbs_dat_o[7:0]),
		.irq_uart_rx(irq_uart_rx),
		.uart_rx(uart_rx)
	);

	wbs_uart_tx #(
		.TICKS_PER_BAUD(TICKS_PER_BAUD)
	) tx (
		.wbs_clk_i(wbs_clk_i),
		.wbs_rst_i(wbs_rst_i),
		.wbs_stb_i(wbs_stb_i & wbs_we_i),
		.wbs_dat_i(wbs_dat_i[7:0]),
		.uart_tx(uart_tx)
	);

	always @(posedge wbs_clk_i) begin
		wbs_ack_o <= wbs_cyc_i && wbs_stb_i;
	end

endmodule
