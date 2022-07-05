// Dear passenger, we are clossing clock domain. Seat comfortably
// and fasten your belt to overcome any turbulence there could be.

module mSpiRx (
	iSpi.mPeri spi,
	iClockDomainCrossing.mExport cdc
);
	logic[2:0] cnt = 0;
	logic[6:0] shifter = 0;
	logic started = 0;
	logic[7:0] shifter_next;

	// export the value read from SPI to the wishbone clock domain
	mClockDomainExporter #(
		.pBits(8)
	)mcdc (
		.clk(spi.sck),
		.data(shifter_next),
		.stb(spi.csn == 0 && cnt == 0 && started),
		.cdc(cdc)
	);

	assign shifter_next = { shifter[6:0], spi.sdi };

	always_ff @(posedge spi.sck) begin

		// prevent to send empty data on first clock
		started <= 1;

		if (spi.csn == 0) begin
			cnt <= cnt + 1;
			shifter <= shifter_next[6:0];
		end
	end
endmodule
