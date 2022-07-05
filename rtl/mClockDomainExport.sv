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
// This part exports a buffer of data to the other clock domain.
// Rising `stb` for one clock queues `data` for transfer. To use
// only when ready.

module mClockDomainExport #(
	parameter pBits = 8
) (
	input logic stb,
	input logic[pBits-1:0] data,
	output logic ready,
	iClockDomain.mExport cdc
);
	logic[1:0] ack_ff;

	// Tools like Verilator warn us that we are crossing clock domains
	// which is what we do so here is how we silence it:
	logic cdc_req;
	logic[pBits-1:0] cdc_data;
	assign cdc.req = cdc_req;
	assign cdc.data = cdc_data;

	assign ready = (ack_ff[0] == cdc_req);

	always_ff @(posedge cdc.clk) begin
		// 2FF buffer to prevent metastable state propagation
		ack_ff <= { cdc.ack, ack_ff[1] };

		if (stb && ready) begin
			cdc_data <= data;
			cdc_req <= !cdc_req;
		end
	end

endmodule
