
module mBlinkenLight#(
	parameter pLeds = 8
) (
	iWishbone wb,
	output logic[pLeds-1:0] blinkenlights
);
	logic[3:0] counter;
	logic request, we, dat_p, dat_c;

	assign blinkenlights = { counter, request, we, dat_c, dat_p };

	always_ff @(posedge wb.clk) begin
		if (wb.ack) begin
			counter <= counter + 1;
			wb.dat_p <= |wb.dat_p;
			wb.dat_c <= 0;
			request <= 0;
		end
		if (wb.stb) begin
			dat_c <= |wb.dat_c;
			dat_i <= 0;
			we <= wb.we;
			request <= 1;
		end
	end

endmodule
