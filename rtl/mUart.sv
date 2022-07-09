`default_nettype none

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
	input	logic clk,
	input	logic rst,
	output	iWishbone_Peri wb_p,
	input	iWishbone_Ctrl wb_c,
	input	logic rx,
	output	logic tx
);
	localparam pTicksPerBaud = pClkHz / pOutputHz;

	assign wb_p.ack = wb_c.stb;

	mUartRx#(.pTicksPerBaud(pTicksPerBaud)) murx(
		.clk, .rst,
		.stb(wb_c.stb & !wb_c.we),
		.data(wb_p.dat),
		.rx
	);

	mUartTx#(.pTicksPerBaud(pTicksPerBaud)) mutx(
		.clk, .rst,
		.stb(wb_c.stb & wb_c.we),
		.data(wb_c.dat),
		.tx
	);
endmodule
