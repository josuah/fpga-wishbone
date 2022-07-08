
module mRgb(
	iWishbone.mPeri wb,
	output logic[2:0] rgb
);
	assign wb.dat_p = 0;

	always_ff @(posedge wb.clk) begin
		wb.ack <= wb.stb;

		if (wb.stb) begin
			rgb <= 3'b111;
		end

		if (wb.rst) begin
			rgb <= 0;
		end
	end

endmodule
