`default_nettype none

// The big challenge with controlling a LED matrix, or even a screen,
// is there will be a large amount of LEDs to wire to a controller.
//
// The obvious solution to wire one LED to one pin is wasting precious
// I/O pins, but permits to display all pixel continuously. This might
// work for integrated circuits where it is possible to add as many
// pins as needed, but still not good for a simple LED matrix display.
//
// A more economical approach is to connect the LEDs in a crossbar:
//
// Here, the screen can be displayed by first connecting A to the
// ground, and take signals ROW[0..3] up or down according to what
// needs to be connected.
//
// This reduces the number of pins from ROW*COL down to only ROW+COL,
// and requires showing one row at a time (the other with light off),
// quickly switching from row to row for providing the illusion of a
// entire surface lit by the LEDs.
//
// It is possible to reduce it even further with charlieplexing [1]:
// the same pins are used for both rows and columns, and the wiring
// is configured to include

module wb_charlie7x5 (
	// Wishbone B4 pipelined
	input wire wb_clk_i,

	// Screen output pins
	output wire [6:0] charlie7x5_o,
	output wire [6:0] charlie7x5_oe
);
	reg [6:0] row = 0;
	reg [6:0] col = 0;

	// 
	wire [6:0] row_pin = (row >= col) ? row + 1 : row;
	wire [6:0] col_pin = col;

	assign charlie7x5_o =	(1 << row_pin);
	assign charlie7x5_oe =	(1 << row_pin) | (1 << col_pin);

	always @(posedge wb_clk_i) begin
		row <= row + 1;

		if (row == 5) begin
			row <= 0;
			col <= col + 1;
		end

		if (col == 7) begin
			col <= 0;
		end
	end

endmodule
