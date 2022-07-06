
interface iClockDomain #(
	parameter pSize = 8
);
	logic req, ack;
	logic[pSize-1:0] data;

	modport mImport (
		output	ack,
		input	data,
		input	req
	);

	modport mExport (
		input	ack,
		output	data,
		output	req
	);

endinterface
