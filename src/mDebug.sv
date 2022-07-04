
module mDebug (
	iWishbone wb,
	output logic[7:0] debug
);
	assign wb.dat_p = 0;

	always_ff @(posedge wb.clk) begin
		wb.ack_o <= wb.stb;
		if (wb.stb && wb.we)
			debug <= wb.dat_c;

		if (wb.rst)
			{ debug } <= 0;
	end

endmodule
