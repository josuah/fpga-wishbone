// This whole module is in its own clock domain, driven by the SCK
// external signal frim SPI
//
// It fills a buffer of 32 bits with a shift register, and once full,
// copies it to a buffer, and sets the the data_ready interrupt

module wbm_spi_rx (
	// spi slave posedge i/o
	input wire spi_sck,
	input wire spi_csn,
	input wire spi_sdi,
	output wire spi_sdo,

	// data transmission
	output reg data_rdy,
	output reg [7:0] data_buf
	input wire data_ack,
);
	reg [7:0] shift_reg = 0;
	reg [2:0] cnt = 0;
	wire shift_reg_next = { shift_reg[7:0], spi_sdi };

	always @(posedge spi_sck) begin
		if (spi_csn) begin
			cnt <= cnt + 1;

			// insert new bits at the lowest position,
			// producing a MSB first number
			shift_reg <= shift_reg_next;

			// when the buffer is full
			if (cnt + 1 == 0) begin
				// serve the data on a plate and ring the bell
				data_rdy <= 1;
				data_buf <= shift_reg_next;
			end
		end
	end

endmodule
