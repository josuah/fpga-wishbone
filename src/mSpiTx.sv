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
	iSpi.peripheral spi,
	iClockDomainCrossing.importer cdc
);
	reg [7:0] shift_reg = 0;
	reg [2:0] cnt = 0;
	wire [7:0] data;
	wire unused = &{ stb };
	wire stb;

	assign spi.sdo = shift_reg[7];

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
			shift_reg <= { shift_reg[6:0], 1'b0 };

			if (cnt == 0) begin
				// continuously transmit `data`
				shift_reg <= data;
			end
		end
	end

endmodule
