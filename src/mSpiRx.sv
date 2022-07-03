// Dear passenger, we are clossing clock domain. Seat comfortably
// and fasten your belt to overcome any turbulence there could be.

module mSpiRx (
	iSpi.peripheral ispi,
	iClockDomainCrossing.export icdc
);
	logic [2:0] cnt = 0;
	logic [7:0] shift_reg = 0;
	logic started = 0;
	logic unused = &{ ready, shift_reg[7] };
	logic ready;
	logic [7:0] shift_reg_next;

	// export the value read from SPI to the wishbone clock domain
	mClockDomainExport#(.SIZE(8)) mcde (
		.clk(ispi.sck),
		.data(shift_reg_next),
		.stb(ispi.csn == 0 && cnt == 0 && started),
		.ready(ready),
		.icdc(i)
		.handshake_req(handshake_req),
		.handshake_ack(handshake_ack),
		.handshake_data(handshake_data)
	);

	assign shift_reg_next = { shift_reg[6:0], ispi.sdi };

	always_ff @(posedge ispi.sck) begin
		// prevent to send empty data on first clock
		started <= 1;
		if (ispi.csn == 0) begin
			cnt <= cnt + 1;
			shift_reg <= shift_reg_next;
		end
	end
endmodule
