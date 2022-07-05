
interface iClockDomainCrossing #(
	parameter pSize = 8
);
	logic[pSize-1:0] data;
	logic req;
	logic ack;

	modport mImport(
		input	data,
		input	req,
		output	ack
	);
	modport mExport(
		output	data,
		output	req,
		input	ack
	);
endinterface
