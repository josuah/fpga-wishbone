
typedef enum {
	eUartState_Idle,
	eUartState_Start,
	eUartState_Bit0,
	eUartState_Bit1,
	eUartState_Bit2,
	eUartState_Bit3,
	eUartState_Bit4,
	eUartState_Bit5,
	eUartState_Bit6,
	eUartState_Bit7,
	eUartState_Stop
} eUartState;

module mUart#(
	parameter pClkHz = 0,
	parameter pOutputHz = 9600
) (
	iWishbone.mPeri wb,
	output logic irq,
	input logic rx,
	output logic tx
);
	localparam lpTicksPerBaud = pClkHz / pOutputHz;

	assign wb.dat_p[31:8] = 0;

	mUartRx#(
		.pTicksPerBaud(lpTicksPerBaud)
	) mrx(
		.clk(wb.clk),
		.rst(wb.rst),
		.stb(wb.stb & !wb.we),
		.data(wb.dat_p[7:0]),
		.irq(irq),
		.rx(rx)
	);

	mUartTx#(
		.pTicksPerBaud(lpTicksPerBaud)
	) mtx(
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
