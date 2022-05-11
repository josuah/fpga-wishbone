// Dear passenger, we are clossing clock domain. Seat comfortably
// and fasten your belt to overcome any turbulence there could be.

module wbm_spi_tx (
	// SPI slave posedge I/O
	input wire spi_sck,
	input wire spi_csn,
	output wire spi_sdo,

	// clock domain crossing
	input wire handshake_wb,
	output reg handshake_spi,
	input wire [7:0] handshake_buffer
);
	reg [7:0] shift_reg = 0;
	reg [2:0] cnt = 0;
	reg ack;

	wire [7:0] data;

	// import the value to send over SPI from the wishbone clock domain
	clock_domain_import cross_import (
		.clk(spi_sck),
		.handshake_buffer(handshake_buffer),
		.handshake_other(handshake_wb),
		.handshake_local(handshake_spi),
		.data(data),
		.ack(ack)
	);

	assign spi_sdo = shift_reg[7];

	always @(posedge spi_sck) begin
		ack <= 0;

		// if we are selected by the SPI controller
		if (spi_csn == 0) begin
			cnt <= cnt + 1;

			shift_reg <= { shift_reg[6:0], 1'b0 };

			if (cnt + 1 == 0) begin
				// continuously transmit the `data`
				shift_reg <= data;

				// release data to the clock_domainer
				ack <= 1;
			end
		end
	end

endmodule
