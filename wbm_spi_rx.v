// Dear passenger, we are clossing clock domain. Seat comfortably
// and fasten your belt to overcome any turbulence there could be.

module wbm_spi_rx (
	// SPI slave posedge I/O
	input wire spi_sck,
	input wire spi_csn,
	input wire spi_sdi,

	// clock domain crossing
	input wire handshake_ack,
	output reg handshake_req,
	output reg [7:0] handshake_data
);
	reg [7:0] data = 0;
	reg stb = 0, stb_next = 0;
	reg [2:0] cnt = 0;
	reg [7:0] shift_reg = 0;
	wire [7:0] shift_reg_next = { shift_reg[6:0], spi_sdi };
	wire unused = &{ ready, shift_reg[7] };
	wire ready;

	// export the value read from SPI to the wishbone clock domain
	clock_domain_export #(
		.SIZE(8)
	) cross_export (
		.clk(spi_sck),
		.data(data),
		.stb(stb),
		.ready(ready),
		.handshake_req(handshake_req),
		.handshake_ack(handshake_ack),
		.handshake_data(handshake_data)
	);

	always @(posedge spi_sck) begin
		stb <= 0;

		// if we are selected by the SPI controller
		if (spi_csn == 0) begin
			cnt <= cnt + 1;
			shift_reg <= shift_reg_next;

			// note: cnt starts at 1
			if (cnt == 0) begin
				// continuously receive into `data`
				data <= shift_reg_next;
				// prevent the first clock to send an empty buffer
				stb <= stb_next;
				stb_next <= 1;
			end
		end
	end

endmodule
