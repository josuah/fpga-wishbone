
interface iWishbone (
	input logic clk, rst
);
	logic stb;
	logic we;
	logic ack;
	logic[3:0] adr;
	logic[7:0] dat_c;
	logic[7:0] dat_p;

	modport peripheral (
		input	stb,
		output	we, 
		input	ack,
		output	adr,
		output	dat_p,
		input	dat_c
	);

	modport controller (
		output	stb,
		output	we, 
		input	ack,
		output	adr,
		input	dat_p,
		output	dat_c
	);

endinterface
