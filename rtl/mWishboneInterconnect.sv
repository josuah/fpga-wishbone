// Designed for a single master such as a MCU, and multiple
// peri. This is the place where addressing of slaves is
// configured.
//
// The input and outputs are looking to be reversed, it is due
// to this piece of code looking from the inside of the crossbar
// so we receive master's output and send to slave's input

module mWishboneInterconnect#(
	parameter pPeri = 0
)(
	input	logic clk,
	input	logic rst,
	input	iWishbone_Ctrl wbc_c,
	output	iWishbone_Peri wbc_p,
	input	iWishbone_Peri[pPeri-1:0] wbp_p,
	output	iWishbone_Ctrl[pPeri-1:0] wbp_c
);
	logic[3:0] addr_buf;
	logic[3:0] addr;

/*
	task tWishboneConnectPeri(input int id);
		wbp_c[id].stb = wbc_c.stb;
		wbc_p.dat = wbp_p[id].dat;
		wbc_p.ack = wbp_p[id].ack;
	endtask

	generate
		for (genvar i = 0; i < pPeri; i++) begin
			assign wbp_c[i].we = wbc_c.we;
			assign wbp_c[i].adr = wbc_c.adr[3:0];
			assign wbp_c[i].dat = wbc_c.dat;
			assign wbp_c[i].stb = wbc_c.stb;
		end
	endgenerate

	always_comb begin
		case (addr)
//		8'b00000000: begin
//			wbp_c[0].stb = wbc_c.stb;
//			wbc_p.dat = wbp_p[0].dat;
//			wbc_p.ack = wbp_p[0].ack;
//		end
		default: begin
			wbc_p.dat = 0;
			wbc_p.ack = 0;
		end
		endcase
	end

	// add persistence to `wb_p.adr`
	assign addr = wbc_c.stb ? wbc_c.adr : addr_buf;

	always_ff @(posedge clk) begin
		addr_buf <= addr;

		if (rst) begin
			addr_buf <= 0;
		end
	end
*/
endmodule
