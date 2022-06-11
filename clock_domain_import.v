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
//   it copies `handshake_data` to a local register (3) then sets `handshake_ack` to the same value as `handshake_req` (4).
//
// References:
// http://web.cse.msu.edu/~cse820/readings/sutherlandMicropipelinesTuring.pdf
// http://www.sunburst-design.com/papers/CummingsSNUG2008Boston_CDC.pdf
// https://zipcpu.com/blog/2018/07/06/afifo.html
// 
// This part imports a buffer of data from the other clock domain.
// As `data` becomes valid, `stb` rises for one clock.

module clock_domain_import #(
	parameter SIZE = 8
) (
	input wire clk,

	// data reception
	output wire [SIZE-1:0] data,
	output wire stb,

	// handshake with the other clock domain
	input wire [SIZE-1:0] handshake_data,
	input wire handshake_req,
	output reg handshake_ack
);
	reg [1:0] handshake_req_ff = 0;

	assign data = handshake_data;
	assign stb = (handshake_req_ff[0] != handshake_ack);

	always @(posedge clk) begin
		// 2FF buffer to prevent metastable state propagation
		handshake_req_ff <= { handshake_req, handshake_req_ff[1] };

		// have the `ack` signal follow the `req` signal
		handshake_ack <= handshake_req_ff[0];
	end
endmodule
