// This clock domain crossing strategy is similar to the well-known
// Valid/Ready with Ack, except that Ready and Ack are merged
// onto an unique signal, and Valid was renamed Req (for request).
// In addition, instead on focusing on these signals being up or
// down, the information is carried by whether they have different
// value (request in progress) or the same value (request completed).
// 
// We end-up with the same protocol, but only two signals for controlling
// the transfer of `handshake_data`:
// 
// * The source module sending the data to another clock domain writes to
//   `handshake_ack` (and reads `handshake_req`).
// * The destination module receiving data from another clock domain writes to
//   `handshake_req` (and reads `handshake_ack`).
// 
//			  :   :   :   :   :   :   :   :   :   :   :   :  
//			__:_______________:_______________:______________
//	handshake_data	__X_______________X_______________X______________
//			  :    _______________:   :   :   :    __________
//	handshake_req	______/   :   :   :   \_______________/   :   :  
//			  :   :   :   :_______________:   :   :   :   :__
//	handshake_ack	______________/   :   :   :   \_______________/  
//			  :   :   :   :   :   :   :   :   :   :   :   :  
//			 (1) (2) (3) (4) (1) (2) (3) (4) (1) (2) (3) (4) 
// 
// * When the source has data to transfer,
//   it first asserts `handshake_data` to the data to transfer (1) then invert `handshake_req` (2).
// * Once the destination notices it,
//   it copies `handshake_data` to a local register (3) then sets `handshake_ack` to the same value as `handshake_req` (4).
//
// References:
// http://web.cse.msu.edu/~cse820/readings/sutherlandMicropipelinesTuring.pdf
// http://www.sunburst-design.com/papers/CummingsSNUG2008Boston_CDC.pdf
// https://zipcpu.com/blog/2018/07/06/afifo.html
// 
// This is the export part, to call from the source module.
// It transmits a buffer of data to other clock domain.
// 
// Rising `stb` for one clock queue `data` for transfer only if `ready` is set.

module clock_domain_export #(
	parameter SIZE = 8
) (
	input wire clk,

	// control interface
	input wire [SIZE-1:0] data,
	input wire stb,
	output wire ready,

	// the "other" clock domain I/O
	output reg [SIZE-1:0] handshake_data,
	output reg handshake_req,
	input wire handshake_ack
);
	reg handshake_ack_x;

	assign ready = (handshake_ack_x == handshake_req);

	always @(posedge clk) begin
		// prevent metastable state propagation
		handshake_ack_x <= handshake_ack;

		if (ready && stb) begin
			handshake_data <= data;
			handshake_req <= !handshake_req;
		end
	end
endmodule
