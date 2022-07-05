
module mDebug (
	iWishbone.mPeri wb,
	output logic[7:0] debug
);
	assign wb.dat_p = 0;

	always_ff @(posedge wb.clk) begin
		wb.ack <= wb.stb;

		if (wb.stb && wb.we) begin
			debug <= wb.dat_c;
		end

		if (wb.rst) begin
			debug <= 0;
		end
	end

endmodule
