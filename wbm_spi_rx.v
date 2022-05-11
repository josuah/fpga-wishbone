// Dear passenger, we are clossing clock domain. Seat comfortably
// and fasten your belt to overcome any turbulence there could be.

module wbm_spi_rx (
	// SPI slave posedge I/O
	input wire spi_sck,
	input wire spi_csn,
	input wire spi_sdi,
	output wire spi_sdo,

	// clock domain crossing
	input wire handshake_wb,
	output reg handshake_spi,
	output reg [7:0] handshake_buffer
);
	reg [7:0] shift_reg = 0, rx_data = 0;
	reg [2:0] cnt = 0;

	wire ack;
	wire [7:0] shift_reg_next = { shift_reg[6:0], spi_sdi };

	clock_domain_crosser #(
		.DATA_OUT(1) // toward the wishbone bus
	) clock_domain_crosser (
		.clk(spi_sck)
		.handshake_buffer(handshake_buffer),
		.handshake_other(handshake_wb),
		.handshake_local(handshake_spi),
		.data(data),
		.ack(ack)
	);

	always @(posedge spi_sck) begin
		ack = 0;

		// if we are selected by the SPI controller
		if (spi_csn == 0) begin
			cnt <= cnt + 1;

			shift_reg <= shift_reg_next;

			if (cnt + 1 == 0) begin
				// continuously receive into `data`
				data <= shift_reg_next;

				// release `data` to the clock_domain_crosser
				ack = 1;
			end
		end
	end

endmodule
