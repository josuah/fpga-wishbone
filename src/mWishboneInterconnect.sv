// Designed for a single master such as a MCU, and multiple
// peripherals. This is the place where addressing of slaves is
// configured.
//
// The input and outputs are looking to be reversed, it is due
// to this piece of code looking from the inside of the crossbar
// so we receive master's output and send to slave's input

module mWishboneInterconnect #(
	parameter pPeriphNum = 0
) (
	iWishboneBus wbc
);
	reg [11:0] peripheral_addr_reg = 0;
	wire [11:0] peripheral_addr;

	// signals from master to slave, that are just direct wires, controlled
	// by CYC signal that tells whether to react or not to them
	assign wbp.cyc = wbc.cyc << peripheral_addr_reg;
	assign wbp.stb = wbc.stb;
	assign wbp.we = wbc.we;
	assign wbp.adr = wbc.adr[3:0];
	assign wbp.sel = wbc.sel;
	assign wbp.dat_c = wbc.dat_c;

	// selecting which peripheral's signal to transmit depending on address
	assign wbc.dat_p = wbs_dat_p >> peripheral_addr * 32;
	assign wbc.ack = wbs_ack >> peripheral_addr;

	// add persistence to `wbs_adr`
	assign peripheral_addr = wbc.cyc && wbc.stb ? wbc.adr[15:4] : peripheral_addr_reg;

	always_ff @(posedge wbc.clk) begin
		peripheral_addr_reg <= peripheral_addr;

		if (wbc.rst) begin
			peripheral_addr_reg <= 0;
		end
	end

endmodule
