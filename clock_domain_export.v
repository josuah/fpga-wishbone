// This clock domain crossing strategy is the same as the well-known
// Valid/Ready with Ack signal, except that Ready and Ack are merged
// onto an unique signal. Ack set low is the same as valid set high.
// 
// We end-up with the same protocol, but only two signals for controlling
// the transfer of `handshake_data`:
// 
// * The source module sending the data to another clock domain writes to
//   `handshake_ack` (and reads `handshake_valid`).
// * The destination module receiving data from another clock domain writes to
//   `handshake_valid` (and reads `handshake_ack`).
// 
//			 :    :   :   :   :        :       :
//			 :    :____________________:       :
//	handshake_data	XXXXXXX____________________XXXXXXXXXXXXX
//			 :    :    ________________:       :
//	handshake_valid	__________/   :   :        \____________
//			 :    :   :   :   :________________:
//	handshake_ack	__________________/        :       \____
//			 :    :   :   :   :        :       :
//			(1)  (2) (3) (4) (5)      (6)     (7)
// 
// * When the source has data to transfer (1),
//   it first asserts `handshake_data` to the appropriate content (2) then sets `handshake_valid` high (3).
// * Once the destination notices it,
//   it copies `handshake_data` to a local register (4) and sets `handshake_ack` high (5).
// * Once the source notices it,
//   it sets `handshake_valid` low, and `handshake_valid` can be set to the next value.
// * Once the destination notices it,
//   it sets `handshake_ack` back to low. It is ready for another cycle.
// 
// This is the export part, to call from the source module.
// It transmits a buffer of data to other clock domain.
// 
// Rising `stb` for one clock queue `data` for transfer unless `busy` is set.

module clock_domain_export #(
	parameter SIZE = 8
) (
	input wire clk,

	// control interface
	input wire [SIZE-1:0] data,
	input wire stb,
	output wire busy,

	// the "other" clock domain I/O
	output reg [SIZE-1:0] handshake_data,
	output reg handshake_valid,
	input wire handshake_ack
);
	localparam STATE_LOAD_DATA = 0;
	localparam STATE_WAIT_ACK = 1;
	localparam STATE_TERMINATE_HANDSHAKE = 2;

	reg [1:0] state = 0;
	reg handshake_ack_x;

	assign busy = (state != STATE_LOAD_DATA);

	always @(posedge clk) begin
		// prevent metastable state propagation
		handshake_ack_x <= handshake_ack;

		case (state)
		STATE_LOAD_DATA: begin
			if (stb) begin
				// `handshake_data` and `handshake_valid` can
				// be sent at the same time as `handshake_data`
				// does not have an extra flip-flop pair and
				// will arrive earlier, as in Fig 1. of
				// https://zipcpu.com/blog/2018/07/06/afifo.html
				handshake_data <= data;
				handshake_valid <= 1;
				state <= STATE_WAIT_ACK;
			end
		end
		STATE_WAIT_ACK: begin
			if (handshake_ack_x)
				state <= STATE_TERMINATE_HANDSHAKE;
		end
		STATE_TERMINATE_HANDSHAKE: begin
			if (handshake_ack_x == 0) begin
				state <= STATE_LOAD_DATA;
				handshake_valid <= 0;
			end
		end
		endcase
	end

endmodule
