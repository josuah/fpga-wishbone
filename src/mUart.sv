
typedef enum logic [3:0] {
	eUartState_IDLE,
	eUartState_START,
	eUartState_BIT_0,
	eUartState_BIT_1,
	eUartState_BIT_2,
	eUartState_BIT_3,
	eUartState_BIT_4,
	eUartState_BIT_5,
	eUartState_BIT_6,
	eUartState_BIT_7,
	eUartState_STOP
} eUartState;

module mUart #(
	parameter pClkHz = 0,
	parameter pOutputHz = 9600
) (
	iWishbone	wb,
	output	wire	irq,
	input	wire	rx,
	output	wire	tx
);
	localparam lpTicksPerBaud = pClkHz / pOutputHz;
	wire unused = &{ wb.dat_c[31:8], wb.dat_p[31:8] };

	assign wb.dat_p[31:8] = 0;

	mUartRx #(
		.pTicksPerBaud(lpTicksPerBaud)
	) mrx (
		.clk(wb.clk),
		.rst(wb.rst),
		.stb(wb.stb & !wb.we),
		.data(wb.dat_p[7:0]),
		.irq(irq),
		.rx(rx)
	);

	mUartTx #(
		.pTicksPerBaud(lpTicksPerBaud)
	) mtx (
		.clk(wb.clk),
		.rst(wb.rst),
		.stb(wb.stb & wb.we),
		.data(wb.dat_c[7:0]),
		.tx(tx)
	);

	always_ff @(posedge wb.clk) begin
		wb.ack_o <= wb.cyc && wb.stb;

		if (wb.rst) begin
			wb.ack_o <= 0;
		end
	end

endmodule
