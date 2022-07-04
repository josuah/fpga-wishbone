// Dear passenger, we are clossing clock domain. Seat comfortably
// and fasten your belt to overcome any turbulence there could be.

module mSpiRx (
	iSpi.peripheral spi,
	iClockDomainCrossing.exporter cdc
);
	logic [2:0] cnt = 0;
	logic [7:0] shift_reg = 0;
	logic started = 0;
	logic unused = &{ ready, shift_reg[7] };
	logic ready;
	logic [7:0] shift_reg_next;

	// export the value read from SPI to the wishbone clock domain
	mClockDomainExporter #(
		.pBits(8)
	) mcde (
		.clk(spi.sck),
		.data(shift_reg_next),
		.stb(spi.csn == 0 && cnt == 0 && started),
		.ready(ready),
		.cdc(cdc)
	);

	assign shift_reg_next = { shift_reg[6:0], spi.sdi };

	always_ff @(posedge spi.sck) begin
		// prevent to send empty data on first clock
		started <= 1;
		if (spi.csn == 0) begin
			cnt <= cnt + 1;
			shift_reg <= shift_reg_next;
		end
	end
endmodule
