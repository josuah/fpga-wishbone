`default_nettype none

module mTestUartRx(
	input	logic clk,
	input	logic rst
);
	logic clk;
	logic rst;
	logic stb;
	logic data;
	logic tx;

	mUartTx#(.pTicksPerBaud(1)) mut(
		.clk, .rst,
		.stb, .data,
		.tx
	);

endmodule
