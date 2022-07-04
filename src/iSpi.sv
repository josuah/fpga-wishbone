
interface iSpi;
	logic sck, csn, sdi, sdo;

	modport peripheral (
		input sck, csn,
		output sdi,
		input sdo
	);

endinterface
