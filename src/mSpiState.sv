`default_nettype none

typedef enum {
	STATE_IDLE,
	STATE_GET_ADDRESS,
	STATE_READ_STALL_ACK,
	STATE_READ_DATA_0,
	STATE_READ_DATA_1,
	STATE_READ_DATA_2,
	STATE_READ_DATA_3,
	STATE_WRITE_DATA_0,
	STATE_WRITE_DATA_1,
	STATE_WRITE_DATA_2,
	STATE_WRITE_DATA_3,
	STATE_WRITE_STALL_ACK
} eSpiState;

module mSpiState (
	iWishbone iw,

	// input/output
	input wire rx_data,
	input wire rx_stb,
	output reg tx_data,
	output reg tx_stb
);
	reg [7:0] tx_data_u8;
	reg state_e state = 0;

	always_ff @(posedge iw.clk) begin
		if (iw.ack) begin
			tx_data_u8 <= iw.dat_p; // only used if iw.we
			iw.stb <= 0;
		end

		// on each byte read, queue one byte to write
		tx_stb <= rx_stb;

		if (rx_stb) begin
			case (state)
			STATE_IDLE: begin		// RX W000SSSS
				iw.we <= rx_data[7];
				tx_data <= 8'h00;	// TX 00000000
				if (|rx_data) // skip 0x00
					state <= STATE_GET_ADDRESS;
			end
			STATE_GET_ADDRESS: begin	// RX AAAAAAAA
				iw.adr <= { 8'b00, rx_data };
				if (iw.we) begin
					// wait to have data to write
					state <= STATE_WRITE_DATA_0;
				end else begin
					// wishbone read with that address
					iw.stb <= 1;
					state <= STATE_READ_STALL_ACK;
				end
			end
			STATE_READ_STALL_ACK: begin	// TX 00000000
				if (!iw.stb) begin	// TX 11111111
					tx_data <= 8'h55;
					state <= STATE_READ_DATA_0;
				end
			end
			STATE_READ_DATA_0,		// TX DDDDDDDD
			STATE_READ_DATA_1,		// TX DDDDDDDD
			STATE_READ_DATA_2: begin	// TX DDDDDDDD
				{ tx_data_u8, tx_data } <= { 8'h00, tx_data_u8 };
				state <= state + 1;
			end
			STATE_READ_DATA_3: begin	// TX DDDDDDDD
				tx_data <= tx_data_u8[7:0];
				state <= STATE_IDLE;
			end
			STATE_WRITE_DATA,		// RX DDDDDDDD
			STATE_WRITE_DATA_1,		// RX DDDDDDDD
			STATE_WRITE_DATA_2: begin	// RX DDDDDDDD
				iw.dat_c <= { iw.dat_c[23:0], rx_data };
				state <= state + 1;
			end
			STATE_WRITE_DATA_3: begin	// RX DDDDDDDD
				iw.dat_c <= { iw.dat_c[23:0], rx_data };
				iw.stb <= 1;
				state <= STATE_WRITE_STALL_ACK;
			end
			STATE_WRITE_STALL_ACK: begin	// TX 00000000
				if (!iw.stb) begin	// TX 11111111
					tx_data <= 8'h55;
					state <= STATE_IDLE;
				end
			end
			endcase
		end

		if (iw.rst)
			{ tx_data, tx_stb, tx_data_u8, state } <= 0;
	end

`ifdef FORMAL

	reg past = 0;

	initial assume(iw.rst == 1);

	always_ff @(posedge iw.clk) begin
		past <= 1;

		if (iw.rst) begin
			assume(rx_stb == 0);
		end

		if (past && $past(iw.rst) == 1)
			assume(iw.rst == 0);
		if (past && $past(iw.rst) == 0)
			assume(iw.rst == 0);

		// we are not expecting to see a slave answer before
		// we actually wait for an answer from a slave
		assume(state == STATE_READ_STALL_ACK || iw.ack == 0);

		if (past && $stable(rx_stb)) begin
			assert($stable(tx_data));
			assert($stable(state));

			if (state != STATE_READ_STALL_ACK) begin
				assert($stable(tx_data_u8));
			end
		end

		if (past && $past(rx_stb) == 1) begin
			if ($past(state == STATE_IDLE) && $past(rx_data)) begin
				assert(state != STATE_IDLE);
			end
		end
	end

`endif

endmodule
