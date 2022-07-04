
interface iClockDomainCrossing #(
	parameter pSize = 8
);
	logic[pSize-1:0] data;
	logic req;
	logic ack;

	modport importer (
		input data,
		input req,
		output ack
	);

	modport exporter (
		output data,
		output req,
		input ack
	);

endinterface
