
interface iSpi;
	logic sck, csn, sdi, sdo;

	modport mPeri(
		input	sck,
		input	csn,
		input	sdi,
		output	sdo
	);
endinterface
