
module mBlinkenLight#(
	parameter pLeds = 8
) (
	iWishbone.mCtrl wb,
	output logic[pLeds-1:0] blinkenlights
);
	logic[3:0] counter;
	logic request, we, dat_p, dat_c;

	assign blinkenlights = {counter, request, we, dat_c, dat_p};

	always_ff @(posedge wb.clk) begin
		if (wb.stb) begin
			dat_c <= |wb.dat_c;
			dat_p <= 0;
			request <= 1;
		end
		if (wb.ack) begin
			dat_p <= |wb.dat_p;
			dat_c <= 0;
			request <= 1;
		end
		if (wb.stb || wb.ack) begin
			we <= wb.we;
			counter <= counter + 1;
		end

		if (wb.rst) begin
			counter <= 4'b1111;
			request <= 1'b1; 
			{we, dat_p, dat_c} <= 0;
		end
	end

endmodule
