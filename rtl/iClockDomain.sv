
interface iClockDomain #(
	parameter pSize = 8
) (
	input clk
);
	logic req, ack;
	logic[pSize-1:0] data;

	modport mImport (
		input	clk,
		output	ack,
		input	data,
		input	req
	);

	modport mExport (
		input	clk,
		input	ack,
		output	data,
		output	req
	);

endinterface
