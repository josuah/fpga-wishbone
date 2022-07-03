`default_nettype none

// Simple handshake protocol for crossing clock domain.
// 
// * The source module sending the data to another clock domain writes to
//   `ack` (and reads `req`).
// * The destination module receiving data from another clock domain writes to
//   `req` (and reads `ack`).
// 
//		  :   :   :   :   :   :   :   :   :   :   :   :  
//		__:_______________:_______________:______________
//	data	__X_______________X_______________X______________
//		  :    _______________:   :   :   :    __________
//	req	______/   :   :   :   \_______________/   :   :  
//		  :   :   :   :_______________:   :   :   :   :__
//	ack	______________/   :   :   :   \_______________/  
//		  :   :   :   :   :   :   :   :   :   :   :   :  
//		 (1) (2) (3) (4) (1) (2) (3) (4) (1) (2) (3) (4) 
// 
// * When the source has data to transfer,
//   it first asserts `data` to the data to transfer (1) then invert `req` (2).
// * Once the destination notices it,
//   it copies `data` to a local register (3) then sets `ack` to
//   the same value as `req` (4).
//
// References:
// http://web.cse.msu.edu/~cse820/readings/sutherlandMicropipelinesTuring.pdf
// http://www.sunburst-design.com/papers/CummingsSNUG2008Boston_CDC.pdf
// https://zipcpu.com/blog/2018/07/06/afifo.html
// 
// This part imports a buffer of data from the other clock domain.
// As `data` becomes valid, `stb` rises for one clock.

module mClockDomainImport #(
	parameter SIZE = 8
) (
	input wire clk,
	output wire [SIZE-1:0] data,
	output wire stb,
	iClockDomainCrossing.import icdc
);
	reg [1:0] req_ff = 0;

	assign data = icdc.data;
	assign stb = (req_ff[0] != icdc.ack);

	always_ff @(posedge clk) begin
		// 2FF buffer to prevent metastable state propagation
		req_ff <= { icdc.req, req_ff[1] };

		// have the `ack` signal follow the `req` signal
		icdc.ack <= req_ff[0];
	end

endmodule
