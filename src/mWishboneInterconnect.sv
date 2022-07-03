// Designed for a single master such as a MCU, and multiple
// peripherals. This is the place where addressing of slaves is
// configured.
//
// The input and outputs are looking to be reversed, it is due
// to this piece of code looking from the inside of the crossbar
// so we receive master's output and send to slave's input

module mWishboneInterconnect #(
	parameter PERIPH_NUM = 0
) (
	iWishbone iw_controller,
	iWishbone [PERIPH_NUM-1:0] iw_peripherals,
);
	localparam CPU_CLK_HZ = 48_000_000;
	reg [11:0] peripheral_addr_reg = 0;
	wire [11:0] peripheral_addr;

	// signals from master to slave, that are just direct wires, controlled
	// by CYC signal that tells whether to react or not to them
	assign wbs_cyc = iw_controller.cyc << peripheral_addr_reg;
	assign wbs_stb = iw_controller.stb;
	assign wbs_we = iw_controller.we;
	assign wbs_adr = iw_controller.adr[3:0];
	assign wbs_sel = iw_controller.sel;
	assign wbs_dat_c = iw_controller.dat_c;

	// selecting which peripheral's signal to transmit depending on address
	assign iw_controller.dat_p = wbs_dat_p >> peripheral_addr * 32;
	assign iw_controller.ack = wbs_ack >> peripheral_addr;

	// add persistence to `wbs_adr`
	assign peripheral_addr = iw_controller.cyc && iw_controller.stb ? iw_controller.adr[15:4] : peripheral_addr_reg;

	always_ff @(posedge wb_clk) begin
		peripheral_addr_reg <= peripheral_addr;

		if (wb_rst)
			peripheral_addr_reg <= 0;
	end

endmodule
