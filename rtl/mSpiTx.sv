
module mSpiTx (
	iSpi.mPeri spi,
	iClockDomain.mImport cdc
);
	logic[7:0] shifter;
	logic[2:0] cnt;
	logic[7:0] data;
	logic unused = &{ stb };
	logic stb;

	assign spi.sdo = shifter[7];

	mClockDomainImport mimp (
		.clk(spi.sck),
		.cdc(cdc),
		.data(data),
		.stb(stb)
	);

	always_ff @(posedge spi.sck) begin
		// if we are selected by the SPI controller
		if (spi.csn == 0) begin
			cnt <= cnt + 1;
			shifter <= { shifter[6:0], 1'b0 };

			if (cnt == 0) begin
				// continuously transmit `data`
				shifter <= data;
			end
		end
	end

endmodule
