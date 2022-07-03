`default_nettype none

module wbs_rgb (
	wishbone wb,
	output wire led_r,
	output wire led_g,
	output wire led_b
);
	reg enabled = 0;
	wire unused = |{ wb.we, wb.adr, wb.sel, wb.dat_c };

	assign wb.dat = 0;

	assign led_r = enabled;
	assign led_g = enabled;
	assign led_b = enabled;

	always_ff @(posedge wb.clk) begin
		wb.ack <= wb.stb;

		if (wb.stb)
			enabled <= 1;

		if (wb.rst)
			{ enabled } <= 0;
	end

endmodule
