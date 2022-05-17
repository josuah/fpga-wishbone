// Wishbone B4 master, itself controlled through an SPI slave
// the MCU on the other end is the SPI master, and (via this
// module) the Wishbone master as well.
//
// Wishbone read:
//
//	W000SSSS AAAAAAAA :::::::: :::::::: :::::::: :::::::: :::::::: ::::::::
//	│   ├──┘ ├──────┘
//	│:::│::: │::::::: 11111111 00000000 DDDDDDDD DDDDDDDD DDDDDDDD DDDDDDDD
//	│   │    │        ├──────┘ ├──────┘ ├─────────────────────────────────┘
//	WE  SEL  ADR      WAIT     ACK      DAT
//
// Wishbone write:
//
//	W000SSSS AAAAAAAA DDDDDDDD DDDDDDDD DDDDDDDD DDDDDDDD :::::::: ::::::::
//	│   ├──┘ ├──────┘ ├─────────────────────────────────┘
//	│:::│::: │::::::: │::::::: :::::::: :::::::: :::::::: 11111111 00000000
//	│   │    │        │                                   ├──────┘ ├──────┘
//	WE  SEL  ADR      DAT                                 WAIT     ACK
//

module wbm_spi (
	// Wishbone B4 pipelined
	input wire wb_clk_i,
	input wire wb_rst_i,
	output wire wb_cyc_o,
	output wire wb_stb_o,
	output wire wb_we_o,
	output wire [3:0] wb_sel_o,
	output wire [15:0] wb_adr_o,
	output wire [31:0] wb_dat_o,
	input wire [31:0] wb_dat_i,
	input wire wb_stall_i,
	input wire wb_ack_i,

	// SPI slave I/O
	input wire spi_sck,
	input wire spi_csn,
	input wire spi_sdi,
	output wire spi_sdo
);
	reg tx_stb;
	reg [7:0] tx_data, rx_data;
	wire [7:0] rx_handshake_data, tx_handshake_data;
	wire rx_handshake_valid, rx_handshake_ack, rx_stb;
	wire tx_handshake_valid, tx_handshake_ack, tx_busy;
	wire unused = &{ tx_busy };


	// transmitter connection //

	clock_domain_export #(
		.SIZE(8)
	) clock_domain_export (
		.clk(wb_clk_i),
		.data(tx_data),
		.stb(tx_stb),
		.busy(tx_busy),
		.handshake_valid(tx_handshake_valid),
		.handshake_ack(tx_handshake_ack),
		.handshake_data(tx_handshake_data)
	);

	wbm_spi_tx wbm_spi_tx (
		.spi_sck(spi_sck),
		.spi_csn(spi_csn),
		.spi_sdo(spi_sdo),
		.handshake_valid(tx_handshake_valid),
		.handshake_ack(tx_handshake_ack),
		.handshake_data(tx_handshake_data)
	);


	// receiver connection //

	clock_domain_import #(
		.SIZE(8)
	) clock_domain_import (
		.clk(wb_clk_i),
		.data(rx_data),
		.stb(rx_stb),
		.handshake_valid(rx_handshake_valid),
		.handshake_ack(rx_handshake_ack),
		.handshake_data(rx_handshake_data)
	);

	wbm_spi_rx wbm_spi_rx (
		.spi_sck(spi_sck),
		.spi_csn(spi_csn),
		.spi_sdi(spi_sdi),
		.handshake_valid(rx_handshake_valid),
		.handshake_ack(rx_handshake_ack),
		.handshake_data(rx_handshake_data)
	);



	// wishbone master //

	localparam STATE_DONE = 0;
	localparam STATE_RX_COMMAND = 0;
	localparam STATE_RX_ADDRESS = 1;
	localparam STATE_RX_DATA_0 = 2;
	localparam STATE_RX_DATA_1 = 3;
	localparam STATE_RX_DATA_2 = 4;
	localparam STATE_RX_DATA_3 = 5;
	localparam STATE_READ_WAIT_ACK = 6;
	localparam STATE_READ_TX_ACK = 7;
	localparam STATE_READ_TX_DATA_0 = 8;
	localparam STATE_READ_TX_DATA_1 = 9;
	localparam STATE_READ_TX_DATA_2 = 10;
	localparam STATE_READ_TX_DATA_3 = 11;
	localparam STATE_WRITE_WAIT_ACK = 11;
	localparam STATE_WRITE_TX_ACK = 12;

	reg [31:0] wb_data = 0;
	reg [3:0] state = 0;

	always @(posedge wb_clk_i) begin
		if (wb_stb_o && !wb_stall_i)
			wb_stb_o <= 0;

		if (rx_stb) begin
			case (state)

			// Common branch

			STATE_RX_COMMAND: begin		// W000SSSS
				// first read instructions from the SPI master
				wb_we_o <= rx_data[7];
				wb_sel_o <= rx_data[3:0];
				state <= STATE_RX_ADDRESS;
			end
			STATE_RX_ADDRESS: begin		// AAAAAAAA
				wb_adr_o <= { 6'b00, rx_data, 2'b00 };
				if (wb_we_o) begin
					// wait to have data to write
					state <= STATE_RX_DATA_0;
				end else begin
					// wishbone read with that address
					wb_cyc_o <= 1;
					wb_stb_o <= 1;
					state <= STATE_READ_WAIT_ACK;
				end
			end
			STATE_RX_DATA_0,		// DDDDDDDD
			STATE_RX_DATA_1,		// DDDDDDDD
			STATE_RX_DATA_2: begin		// DDDDDDDD
				wb_dat_o <= { wb_dat_o[23:0], rx_data };
				state <= state + 1;
			end
			STATE_RX_DATA_3: begin		// DDDDDDDD
				wb_dat_o <= { wb_dat_o[23:0], rx_data };
				wb_cyc_o <= 1;
				wb_stb_o <= 1;
				state <= STATE_WRITE_WAIT_ACK;
			end

			// Wishbone read branch

			STATE_READ_WAIT_ACK: begin	// 11111111
				tx_data <= 8'hFF;
				tx_stb <= 1;
				// see below
			end
			STATE_READ_TX_ACK: begin	// 00000000
				tx_data <= 8'h00;
				tx_stb <= 1;
				state <= STATE_READ_TX_DATA_0;
			end
			STATE_READ_TX_DATA_0,		// DDDDDDDD
			STATE_READ_TX_DATA_1,		// DDDDDDDD
			STATE_READ_TX_DATA_2: begin	// DDDDDDDD
				{ wb_data, tx_data } <= { 8'h00, wb_data };
				tx_stb <= 1;
				state <= state + 1;
			end
			STATE_READ_TX_DATA_3: begin	// DDDDDDDD
				tx_data <= wb_data[7:0];
				tx_stb <= 1;
				state <= STATE_DONE;
			end

			// Wishbone write branch

			STATE_WRITE_WAIT_ACK: begin	// 11111111
				tx_data <= 8'hFF;
				tx_stb <= 1;
				// see below
			end
			STATE_WRITE_TX_ACK: begin	// 00000000
				tx_data <= 8'h00;
				tx_stb <= 1;
				state <= STATE_DONE;
			end
			endcase
		end

		if (state == STATE_READ_WAIT_ACK && wb_ack_i) begin
			wb_data <= wb_dat_i;
			state <= STATE_READ_TX_DATA_0;
		end
		if (state == STATE_WRITE_WAIT_ACK && wb_ack_i) begin
			state <= STATE_WRITE_TX_ACK;
		end
	end

	always @(posedge wb_clk_i) begin
		if (wb_rst_i)
			{ tx_data, rx_data, tx_stb, wb_data, state } <= 0;
	end

endmodule
