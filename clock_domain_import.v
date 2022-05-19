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
	output reg [SIZE-1:0] data,
	output reg stb,

	// handshake with the other clock domain
	input wire [SIZE-1:0] handshake_data,
	input wire handshake_req,
	output reg handshake_ack
);
	reg handshake_req_x = 0;

	always @(posedge clk) begin
		// prevent metastable state propagation
		handshake_req_x <= handshake_req;

		stb <= 0;
		if (handshake_req_x != handshake_ack) begin
			data <= handshake_data;
			stb <= 1;
			handshake_ack <= handshake_req_x;
		end
	end
endmodule
