// Dear passenger, we are clossing clock domain. Seat comfortably
// and fasten your belt to overcome any turbulence there could be.
//
// The `data` register is sampled each time a byte is sent, and the
// parent module has to fill it at regular interval, not too close
// to the last moment to avoid missing a cycle.
//
// The RX signal can be used as a trigger for when to feed the TX data
// on a regular basis.

module mSpiTx (
	iSpi.mPeri spi,
	iClockDomainCrossing.mImport cdc
);
	logic[7:0] shifter;
	logic[2:0] cnt;
	logic[7:0] data;
	logic unused = &{ stb };
	logic stb;

	assign spi.sdo = shifter[7];

	// import the value to send over SPI from the wishbone clock domain
	mClockDomainImporter #(
		.pBits(8)
	) mcdi (
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
