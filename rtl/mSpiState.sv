// Wishbone read:
//
//	W000SSSS AAAAAAAA :::::::: :::::::: :::::::: :::::::: :::::::: ::::::::
//	│   ├──┘ ├──────┘
//	│:::│::: │::::::: 00000000 11111111 DDDDDDDD DDDDDDDD DDDDDDDD DDDDDDDD
//	│   │    │        ├──────┘ ├──────┘ ├─────────────────────────────────┘
//	WE  SEL  ADR      STALL    ACK      DAT
//
// Wishbone write:
//
//	W000SSSS AAAAAAAA DDDDDDDD DDDDDDDD DDDDDDDD DDDDDDDD :::::::: ::::::::
//	│   ├──┘ ├──────┘ ├─────────────────────────────────┘
//	│:::│::: │::::::: │::::::: :::::::: :::::::: :::::::: 00000000 11111111
//	│   │    │        │                                   ├──────┘ ├──────┘
//	WE  SEL  ADR      DAT                                 STALL    ACK
//

typedef enum {
	eSpiState_Idle,
	eSpiState_GetAddress,
	eSpiState_ReadStallAck,
	eSpiState_ReadData,
	eSpiState_WriteData,
	eSpiState_WriteStallAck
} eSpiState;

module mSpiState (
	iWishbone.mCtrl wb,
	input logic[7:0] rx_data,
	input logic rx_stb,
	output logic[7:0] tx_data,
	output logic tx_stb
);
	logic[7:0] tx_data_buf;
	eSpiState state;

	always_ff @(posedge wb.clk) begin
		if (wb.ack) begin
			tx_data_buf <= wb.dat_p; // only used if wb.we
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
				wb.adr <= { rx_data[3:0] }; // TODO: decide on an address length
				if (wb.we) begin
					// wait to have data to write
					state <= eSpiState_WriteData;
				end else begin
					// wishbone read with that address
					wb.stb <= 1;
					state <= eSpiState_ReadStallAck;
				end
			end
			eSpiState_ReadStallAck: begin	// TX 00000000
				if (!wb.stb) begin	// TX 11111111
					tx_data <= 8'h55;
					state <= eSpiState_ReadData;
				end
			end
			eSpiState_ReadData: begin	// TX DDDDDDDD
				tx_data <= tx_data_buf;
				state <= eSpiState_Idle;
			end
			eSpiState_WriteData: begin	// RX DDDDDDDD
				wb.dat_c <= rx_data;
				state <= eSpiState_WriteStallAck;
				wb.stb <= 1;
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
			{ tx_data, tx_stb, tx_data_buf, state } <= 0;
		end
	end

`ifdef FORMAL

	logic past = 0;

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
				assert($stable(tx_data_buf));
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
