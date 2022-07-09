
module mSpiRx(
	input	iSpi_Ctrl spi_c,
	output	iSpi_Peri spi_p,
	input	iClockDomain_Imp cd_i,
	output	iClockDomain_Exp cd_e
);
	logic[2:0] cnt;
	logic[6:0] shifter;
	logic started;
	logic[7:0] shifter_next;
	logic unused;

	mClockDomainExporter mcde(
		.clk(spi_c.sck),
		.cd_e,
		.cd_i,
		.data(shifter_next),
		.stb(spi.csn == 0 && cnt == 0 && started),
		.ready(unused),
	);

	assign shifter_next = {shifter[6:0], spi.sdi};

	always_ff @(posedge spi.sck) begin
		if (spi.csn == 0) begin
			// prevent reception of empty data on first clock
			started <= 1;

			if (spi.csn == 0) begin
				cnt <= cnt + 1;
				shifter <= shifter_next[6:0];
			end
		end
	end

endmodule
