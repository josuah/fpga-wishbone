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
// This part is called from the destination module.
// It imports a buffer of data from the other clock domain.
// 
// As `data` becomes valid, `stb` rises for one clock.

module clock_domain_import #(
	parameter SIZE = 8
) (
	input wire clk,

	// data reception interface
	output reg [SIZE-1:0] data,
	output reg stb,

	// handshake with the other clock domain
	input wire [SIZE-1:0] handshake_data,
	input wire handshake_valid,
	output reg handshake_ack
);
	localparam STATE_LOAD_DATA = 0;
	localparam STATE_ACKNOWLEDGE_DATA = 1;

	reg [0:0] state = 0;
	reg handshake_valid_x = 0;

	always @(posedge clk) begin
		// prevent metastable state propagation
		handshake_valid_x <= handshake_valid;

		stb <= 0;

		case (state)
		STATE_LOAD_DATA: begin
			if (handshake_valid_x) begin
				data <= handshake_data;
				stb <= 1;
				state <= STATE_ACKNOWLEDGE_DATA;
			end
		end
		STATE_ACKNOWLEDGE_DATA: begin
			handshake_ack <= 1;
			if (handshake_valid_x == 0) begin
				handshake_ack <= 0;
				state <= STATE_LOAD_DATA;
			end
		end
		endcase
	end

endmodule
