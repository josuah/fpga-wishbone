
module mSpiTx (
	output	iSpi_Peri spi_p,
	input	iSpi_Ctrl spi_c,
	output	iClockDomain_Imp cd_i,
	input	iClockDomain_Exp cd_e
);
	logic[7:0] shifter;
	logic[2:0] cnt;
	logic[7:0] data;
	logic unused = stb;
	logic stb;

	assign spi.sdo = shifter[7];

	mClockDomainImporter mcdi(
		.clk(spi.sck),
		.cd_i, .cd_e,
		.stb,
		.data
	);

	always_ff @(posedge spi.sck) begin
		// if we are selected by the SPI controller
		if (spi.csn == 0) begin
			cnt <= cnt + 1;
			shifter <= {shifter[6:0], 1'b0};

			if (cnt == 0) begin
				// continuously transmit `data`
				shifter <= data;
			end
		end
	end

endmodule
