`default_nettype none

module wbs_uart #(
	parameter WB_CLK_HZ = 0,
	parameter OUTPUT_HZ = 9600
) (
	iWishbone	iw,
	output	wire	irq,
	input	wire	rx,
	output	wire	tx
);
	localparam TICKS_PER_BAUD = WB_CLK_HZ / OUTPUT_HZ;
	wire unused = &{ iw.dat_c[31:8], iw.dat_p[31:8] };

	assign iw.dat_p[31:8] = 0;

	wbs_uart_rx #(
		.TICKS_PER_BAUD(TICKS_PER_BAUD)
	) rx (
		.clk(iw.clk),
		.rst(iw.rst),
		.stb(iw.stb & !iw.we),
		.data(iw.dat_p[7:0]),
		.irq(irq),
		.rx(rx)
	);

	wbs_uart_tx #(
		.TICKS_PER_BAUD(TICKS_PER_BAUD)
	) tx (
		.clk(iw.clk),
		.rst(iw.rst),
		.stb(iw.stb & iw.we),
		.data(iw.dat_c[7:0]),
		.tx(tx)
	);

	always_ff @(posedge iw.clk) begin
		iw.ack_o <= iw.cyc && iw.stb;
	end

endmodule
