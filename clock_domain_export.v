// Simple handshake protocol for crossing clock domain.
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
//   it copies `handshake_data` to a local register (3) then sets `handshake_ack` to
//   the same value as `handshake_req` (4).
//
// References:
// http://web.cse.msu.edu/~cse820/readings/sutherlandMicropipelinesTuring.pdf
// http://www.sunburst-design.com/papers/CummingsSNUG2008Boston_CDC.pdf
// https://zipcpu.com/blog/2018/07/06/afifo.html
// 
// This part exports a buffer of data to the other clock domain.
// When `ready` is set, rising `stb` for one clock queues `data` for transfer .

module clock_domain_export #(
	parameter SIZE = 8
) (
	input wire clk,

	// data submission
	input wire [SIZE-1:0] data,
	input wire stb,
	output wire ready,

	// handshake with the other clock domain
	output reg [SIZE-1:0] handshake_data,
	output reg handshake_req,
	input wire handshake_ack
);
	reg [1:0] handshake_ack_ff;
	assign ready = (handshake_ack_ff[0] == handshake_req);

	always @(posedge clk) begin
		// 2FF buffer to prevent metastable state propagation
		handshake_ack_ff <= { handshake_ack, handshake_ack_ff[1] };

		if (ready && stb) begin
			handshake_data <= data;
			handshake_req <= !handshake_req;
		end
	end
endmodule
