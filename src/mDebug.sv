`default_nettype none

module wbs_debug (
	wishbone wb,

	// Debug LEDs
	output reg [7:0] debug
);
	wire unused = |{ wb.we, wb.adr };

	assign wb.dat_p = 0;

	always_ff @(posedge wb.clk) begin
		wb.ack_o <= wb.stb;
		if (wb.stb && wb.we)
			debug <= wb.dat_c;

		if (wb.rst)
			{ debug } <= 0;
	end

endmodule
