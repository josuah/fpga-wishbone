
typedef enum {
	eSpiState_Idle,
	eSpiState_GetAddress,
	eSpiState_ReadStallAck,
	eSpiState_ReadData0,
	eSpiState_ReadData1,
	eSpiState_ReadData2,
	eSpiState_ReadData3,
	eSpiState_WriteData0,
	eSpiState_WriteData1,
	eSpiState_WriteData2,
	eSpiState_WriteData3,
	eSpiState_WriteStallAck
} eSpiState;

module mSpiState (
	iWishbone wb,
	input wire rx_data,
	input wire rx_stb,
	output reg tx_data,
	output reg tx_stb
);
	logic[7:0] tx_data_u8;
	eSpiState state;

	always_ff @(posedge wb.clk) begin
		if (wb.ack) begin
			tx_data_u8 <= wb.dat_p; // only used if wb.we
			wb.stb <= 0;
		end

		// on each byte read, queue one byte to write
		tx_stb <= rx_stb;

		if (rx_stb) begin
			case (state)
			eSpiState_Idle: begin		// RX W000SSSS
				wb.we <= rx_data[7];
				tx_data <= 8'h00;	// TX 00000000
				if (|rx_data) // skip 0x00
					state <= eSpiState_GetAddress;
			end
			eSpiState_GetAddress: begin	// RX AAAAAAAA
				wb.adr <= { 8'b00, rx_data };
				if (wb.we) begin
					// wait to have data to write
					state <= eSpiState_WriteData0;
				end else begin
					// wishbone read with that address
					wb.stb <= 1;
					state <= eSpiState_ReadStallAck;
				end
			end
			eSpiState_ReadStallAck: begin	// TX 00000000
				if (!wb.stb) begin	// TX 11111111
					tx_data <= 8'h55;
					state <= eSpiState_ReadData0;
				end
			end
			eSpiState_ReadData0,		// TX DDDDDDDD
			eSpiState_ReadData1,		// TX DDDDDDDD
			eSpiState_ReadData2: begin	// TX DDDDDDDD
				{ tx_data_u8, tx_data } <= { 8'h00, tx_data_u8 };
				state <= state + 1;
			end
			eSpiState_ReadData3: begin	// TX DDDDDDDD
				tx_data <= tx_data_u8[7:0];
				state <= eSpiState_Idle;
			end
			eSpiState_WriteDATA,		// RX DDDDDDDD
			eSpiState_WriteData1,		// RX DDDDDDDD
			eSpiState_WriteData2: begin	// RX DDDDDDDD
				wb.dat_c <= { wb.dat_c[23:0], rx_data };
				state <= state + 1;
			end
			eSpiState_WriteData3: begin	// RX DDDDDDDD
				wb.dat_c <= { wb.dat_c[23:0], rx_data };
				wb.stb <= 1;
				state <= eSpiState_WriteStallAck;
			end
			eSpiState_WriteStallAck: begin	// TX 00000000
				if (!wb.stb) begin	// TX 11111111
					tx_data <= 8'h55;
					state <= eSpiState_Idle;
				end
			end
			endcase
		end

		if (wb.rst) begin
			{ tx_data, tx_stb, tx_data_u8, state } <= 0;
		end
	end

`ifdef FORMAL

	reg past = 0;

	initial assume(wb.rst == 1);

	always_ff @(posedge wb.clk) begin
		past <= 1;

		if (wb.rst) begin
			assume(rx_stb == 0);
		end

		if (past && $past(wb.rst) == 1)
			assume(wb.rst == 0);
		if (past && $past(wb.rst) == 0)
			assume(wb.rst == 0);

		// we are not expecting to see a slave answer before
		// we actually wait for an answer from a slave
		assume(state == eSpiState_ReadStallAck || wb.ack == 0);

		if (past && $stable(rx_stb)) begin
			assert($stable(tx_data));
			assert($stable(state));

			if (state != eSpiState_ReadStallAck) begin
				assert($stable(tx_data_u8));
			end
		end

		if (past && $past(rx_stb) == 1) begin
			if ($past(state == eSpiState_Idle) && $past(rx_data)) begin
				assert(state != eSpiState_Idle);
			end
		end
	end

`endif

endmodule
