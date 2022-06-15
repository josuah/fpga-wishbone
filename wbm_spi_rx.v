// Dear passenger, we are clossing clock domain. Seat comfortably
// and fasten your belt to overcome any turbulence there could be.

module wbm_spi_rx (
	// SPI slave posedge I/O
	input wire spi_sck,
	input wire spi_csn,
	input wire spi_sdi,

	// Clock Domain Crossing
	input wire handshake_ack,
	output reg handshake_req,
	output reg [7:0] handshake_data
);
	reg [2:0] cnt = 0;
	reg [7:0] shift_reg = 0;
	reg started = 0;
	wire unused = &{ ready, shift_reg[7] };
	wire ready;
	wire [7:0] shift_reg_next;

	// export the value read from SPI to the wishbone clock domain
	clock_domain_export #(
		.SIZE(8)
	) cross_export (
		.clk(spi_sck),
		.data(shift_reg_next),
		.stb(spi_csn == 0 && cnt == 0 && started),
		.ready(ready),
		.handshake_req(handshake_req),
		.handshake_ack(handshake_ack),
		.handshake_data(handshake_data)
	);

	assign shift_reg_next = { shift_reg[6:0], spi_sdi };

	always @(posedge spi_sck) begin
		// prevent to send empty data on first clock
		started <= 1;
		if (spi_csn == 0) begin
			cnt <= cnt + 1;
			shift_reg <= shift_reg_next;
		end
	end

endmodule
