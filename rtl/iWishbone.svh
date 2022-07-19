`default_nettype none
`ifndef iWishbone
`define iWishbone

typedef struct packed {
	logic ack;
	logic[7:0] dat;
} iWishbone_Peri;

typedef struct packed {
	logic stb;
	logic we;
	logic[3:0] adr;
	logic[7:0] dat;
} iWishbone_Ctrl;

`endif
