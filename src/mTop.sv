
module mTop #(
	parameter nTicksPerBaud = 4,
	parameter nPeriph = 1,
	parameter nCpuHz = 48_000_000
) (
	input logic clk,
	input logic spi_sck,
	input logic spi_csn,
	input logic spi_sdi,
	input logic spi_sdo,
	output logic[6:0] charlieplex_o, charlieplex_oe,
	output logic[2:0] rgb,
	output logic [7:0] debug
);
	logic rst_n = 0;
	logic counter = 0;
	logic rst = !rst_n;

	iWishbone.controller wbc;
	iWishbone.peripheral wbp[nPeriph-1:0];
	iSpi.peripheral spi;

	assign spi.sck = spi_sck;
	assign spi.csn = spi_csn;
	assign spi.sdi = spi_sdi;
	assign spi.sdo = spi_sdo;

	assign charlieplex_o = 0;
	assign charlieplex_oe = 0;

	mWishboneInterconnect#( .nPeriph(nPeriph) ) wbint (
		.clk(clk), .rst(rst),
		.wbc(wbc), .wbp(wbp)
	);

	mSpi mspi (
		.wb(wbc),
		.spi(spi)
	);

//	mBlinkenlight mBlinkenlight ( .wb(wbc), .blinkenlight(debug) );

	mCharlieplex#( .nCpuHz(nCpuHz) ) wbs0 (
		.wb(wbp),
		.charlieplex_o(charlieplex_o),
		.charlieplex_oe(charlieplex_oe)
	);

//	assign rgb = { counter, 2'b00 };

	mRgb wb0 (
		.wb(wbp), .rgb(rgb)
	);

//	mDebug wb0 ( .wb(wbp), .debug );

	always_ff @(posedge clk) begin
		rst_n <= 1;
		counter <= !counter;
	end

endmodule
