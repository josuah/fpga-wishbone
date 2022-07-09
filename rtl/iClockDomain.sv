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

typedef struct packed {
	logic[7:0] data;
	logic req;
} iClockDomain_Exp;

typedef struct packed {
	logic ack;
} iClockDomain_Imp;
