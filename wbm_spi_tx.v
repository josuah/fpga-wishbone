// Dear passenger, we are clossing clock domain. Seat comfortably
// and fasten your belt to overcome any turbulence there could be.

module wbm_spi_tx (
	// SPI slave posedge I/O
	input wire spi_sck,
	input wire spi_csn,
	input wire spi_sdi,
	output wire spi_sdo,

	// clock domain crossing
	input wire handshake_wb,
	output reg handshake_spi,
	input wire [7:0] handshake_data
);
	reg [7:0] tx_data = 0;
	reg tx_busy = 0;


	// clock domain crossing //

	// see wbm_spi.md
	localparam STATE_1_WAIT_WB_UP = 0;
	// extra state to avoid *metastable* state on handshake_data:
	localparam STATE_3_WAIT_DATA_STABLE = 1;
	localparam STATE_4_WAIT_WB_DOWN = 2;

	reg [1:0] state;

	// as we are clocked by the SCK clock, it has to take less
	// than 8 clocks (number of bits) to operate or we will fall behind.
	always @(posedge spi_sck) begin
		case (state) 
		STATE_1_WAIT_WB_UP: begin
			// also wait that we are ready to transmit the next byte
			if (handshake_wb == 1 && !tx_busy) begin
				// we just checked on both side: we can cross
				// the street, err... I mean the clock domain
				tx_data <= handshake_data;
				tx_busy <= 1;
				state <= STATE_3_WAIT_DATA_STABLE;
			end
		end
		STATE_3_WAIT_DATA_STABLE: begin
			// inform the parent module that we have the data
			handshake_spi <= 1;
			state <= STATE_4_WAIT_WB_DOWN;
		end
		STATE_4_WAIT_WB_DOWN: begin
			if (handshake_wb == 0) begin
				handshake_spi <= 0;
			end
		end
		endcase
	end


	// transfer logic //

	reg [7:0] shift_reg;
	reg [2:0] cnt;

	assign spi_sdo = shift_reg[7];

	always @(posedge spi_sck) begin
		// if we are selected by the SPI controller
		if (spi_csn == 0) begin
			cnt <= cnt + 1;

			shift_reg <= { shift_reg[7:1], 1'b0 };

			if (cnt + 1 == 0) begin
				shift_reg <= tx_data;
				tx_busy <= 0;
			end
		end
	end

endmodule
