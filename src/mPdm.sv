
module mPdm #(
	parameter pBits = 8,
	parameter pChannels = 0
) (
	iWishbone wb,
	output logic[pChannels-1:0] pdm
);
	logic request;

	assign wb.dat_p = 0;
	assign request = wb.stb & wb.we;

	mPdmChannel #(
		.pBits(pBits)
	) channel[pChannels-1:0] (
		.clk(wb.clk),
		.rst(wb.rst),
		.stb({ {pChannels-1{1'b0}}, request } << wb.adr),
		.data(wb.dat_c[pBits-1:0]),
		.pdm(pdm)
	);

	always_ff @(posedge wb.clk) begin
		wb.ack <= wb.stb;
	end
endmodule
