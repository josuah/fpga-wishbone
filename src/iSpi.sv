
interface iSpi;
	logic sck, csn, sdi, sdo;

	modport controller (
		output sck, csn,
		input sdi,
		output sdo
	);

	modport peripheral (
		input sck, csn,
		output sdi,
		input sdo
	);

endinterface
