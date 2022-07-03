
interface iClockDomainCrossing #(
	parameter SIZE = 8
);
	logic [SIZE-1:0] data;
	logic req;
	logic ack;

	modport import (
		input data,
		input req,
		output ack
	);

	modport export (
		output data,
		output req,
		input ack
	);

endinterface
