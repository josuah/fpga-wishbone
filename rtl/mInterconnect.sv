// Designed for a single master such as a MCU, and multiple
// peri. This is the place where addressing of slaves is
// configured.
//
// The input and outputs are looking to be reversed, it is due
// to this piece of code looking from the inside of the crossbar
// so we receive master's output and send to slave's input

module mInterconnect(
	iWishbone ctrl,
	iWishbone peri
);
	logic[3:0] peri_addr_buf;
	logic[3:0] peri_addr;

	// signals from master to slave, that are just direct wires, controlled
	// by CYC signal that tells whether to react or not to them
	assign peri.stb = ctrl.stb << peri_addr_buf;
	assign peri.we = ctrl.we;
	assign peri.adr = ctrl.adr[3:0];
	assign peri.dat_c = ctrl.dat_c;

	// selecting which peri's signal to transmit depending on address
	assign ctrl.dat_p = peri.dat_p >> peri_addr * 32;
	assign ctrl.ack = peri.ack >> peri_addr;

	// add persistence to `peri.adr`
	assign peri_addr = ctrl.stb ? ctrl.adr : peri_addr_buf;

	always_ff @(posedge ctrl.clk) begin
		peri_addr_buf <= peri_addr;

		if (ctrl.rst) begin
			peri_addr_buf <= 0;
		end
	end

endmodule
