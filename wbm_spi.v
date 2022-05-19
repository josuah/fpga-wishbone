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
	output reg wb_cyc_o,
	output reg wb_stb_o,
	output reg wb_we_o,
	output reg [3:0] wb_sel_o,
	output reg [15:0] wb_adr_o,
	output reg [31:0] wb_dat_o,
	input wire [31:0] wb_dat_i,
	input wire wb_stall_i,
	input wire wb_ack_i,

	// SPI slave I/O
	input wire spi_sck,
	input wire spi_csn,
	input wire spi_sdi,
	output wire spi_sdo
);
	reg tx_stb = 0;
	reg [7:0] tx_data = 0;
	wire [7:0] rx_handshake_data, tx_handshake_data, rx_data;
	wire rx_handshake_req, rx_handshake_ack, rx_stb;
	wire tx_handshake_req, tx_handshake_ack, tx_ready;
	wire unused = &{ tx_ready };

	// transmitter connection //

	clock_domain_export #(
		.SIZE(8)
	) clock_domain_export (
		.clk(wb_clk_i),
		.data(tx_data),
		.stb(tx_stb),
		.ready(tx_ready),
		.handshake_req(tx_handshake_req),
		.handshake_ack(tx_handshake_ack),
		.handshake_data(tx_handshake_data)
	);

	wbm_spi_tx wbm_spi_tx (
		.spi_sck(spi_sck),
		.spi_csn(spi_csn),
		.spi_sdo(spi_sdo),
		.handshake_req(tx_handshake_req),
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
		.handshake_req(rx_handshake_req),
		.handshake_ack(rx_handshake_ack),
		.handshake_data(rx_handshake_data)
	);

	wbm_spi_rx wbm_spi_rx (
		.spi_sck(spi_sck),
		.spi_csn(spi_csn),
		.spi_sdi(spi_sdi),
		.handshake_req(rx_handshake_req),
		.handshake_ack(rx_handshake_ack),
		.handshake_data(rx_handshake_data)
	);

	// wishbone master //

	localparam STATE_DONE = 0; // same as STATE_GET_COMMAND
	localparam STATE_GET_COMMAND = 0;
	localparam STATE_GET_ADDRESS = 1;
	localparam STATE_READ_WAIT_ACK = 2;
	localparam STATE_READ_DATA_0 = 3;
	localparam STATE_READ_DATA_1 = 4;
	localparam STATE_READ_DATA_2 = 5;
	localparam STATE_READ_DATA_3 = 6;
	localparam STATE_WRITE_DATA_0 = 7;
	localparam STATE_WRITE_DATA_1 = 8;
	localparam STATE_WRITE_DATA_2 = 9;
	localparam STATE_WRITE_DATA_3 = 10;
	localparam STATE_WRITE_WAIT_ACK = 11;

	reg [31:0] wb_data = 0;
	reg [3:0] state = 0;

	always @(posedge wb_clk_i) begin
		if (wb_stb_o && !wb_stall_i)
			wb_stb_o <= 0;
		if (wb_ack_i) begin
			wb_cyc_o <= 0;
			wb_data <= wb_dat_i; // OK if bad: only used if valid
		end
	end

	always @(posedge wb_clk_i) begin
		// continuously send whatever is in `wb_data`
		tx_stb <= rx_stb;

		if (rx_stb) begin
			case (state)

			// Common branch

			STATE_GET_COMMAND: begin	// RX W000SSSS
				wb_we_o <= rx_data[7];
				wb_sel_o <= rx_data[3:0];
				tx_data <= 8'hFF;	// TX 11111111
				state <= STATE_GET_ADDRESS;
			end
			STATE_GET_ADDRESS: begin	// RX AAAAAAAA
				wb_adr_o <= { 6'b00, rx_data, 2'b00 };
				if (wb_we_o) begin
					// wait to have data to write
					state <= STATE_WRITE_DATA_0;
				end else begin
					// wishbone read with that address
					wb_stb_o <= 1;
					wb_cyc_o <= 1;
					state <= STATE_READ_WAIT_ACK;
				end
			end

			// Wishbone read branch

			STATE_READ_WAIT_ACK: begin	// TX 11111111
				if (!wb_cyc_o) begin	// TX 00000000
					tx_data <= 8'h00;
					state <= STATE_READ_DATA_0;
				end
			end
			STATE_READ_DATA_0,		// TX DDDDDDDD
			STATE_READ_DATA_1,		// TX DDDDDDDD
			STATE_READ_DATA_2: begin	// TX DDDDDDDD
				{ wb_data, tx_data } <= { 8'h00, wb_data };
				state <= state + 1;
			end
			STATE_READ_DATA_3: begin	// TX DDDDDDDD
				tx_data <= wb_data[7:0];
				state <= STATE_DONE;
			end

			// Wishbone write branch

			STATE_WRITE_DATA_0,		// RX DDDDDDDD
			STATE_WRITE_DATA_1,		// RX DDDDDDDD
			STATE_WRITE_DATA_2: begin	// RX DDDDDDDD
				wb_dat_o <= { wb_dat_o[23:0], rx_data };
				state <= state + 1;
			end
			STATE_WRITE_DATA_3: begin	// RX DDDDDDDD
				wb_dat_o <= { wb_dat_o[23:0], rx_data };
				wb_stb_o <= 1;
				wb_cyc_o <= 1;
				state <= STATE_WRITE_WAIT_ACK;
			end
			STATE_WRITE_WAIT_ACK: begin	// TX 11111111
				if (!wb_cyc_o) begin	// TX 00000000
					tx_data <= 8'h00;
					state <= STATE_DONE;
				end
			end
			endcase
		end
	end

	always @(posedge wb_clk_i) begin
		if (wb_rst_i)
			{ tx_data, tx_stb, wb_data, state } <= 0;
	end

endmodule
