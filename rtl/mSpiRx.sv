
module mSpiRx (
	iSpi.mPeri spi,
	//iClockDomain cdc
	output logic[7:0] cdc_data,
	output logic cdc_req,
	input logic cdc_ack
);
	logic[2:0] cnt;
	logic[6:0] shifter;
	logic started;
	logic[7:0] shifter_next;
	logic unused;

	mClockDomainExport mexp(
		.clk(spi.sck),
		.data(shifter_next),
		.stb(spi.csn == 0 && cnt == 0 && started),
		.ready(unused),
		.cdc_data(cdc_data),
		.cdc_req(cdc_req),
		.cdc_ack(cdc_ack)
	);

	assign shifter_next = { shifter[6:0], spi.sdi };

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
