module mTop
//	parameter pCpuHz = 48_000_000
(
	input logic clk,
	input logic spi_sck,
	input logic spi_csn,
	input logic spi_sdi,
	output logic spi_sdo,
	output logic[6:0] charlieplex_o, charlieplex_oe,
	output logic[2:0] rgb,
	output logic[7:0] debug
);
	logic rst_n = 0;
	logic counter = 0;
	logic rst = !rst_n;

	iWishbone wbc( .clk(clk), .rst(rst) );

	iWishbone wbp( .clk(clk), .rst(rst) );

	iSpi spi();
	assign spi.sck = spi_sck;
	assign spi.csn = spi_csn;
	assign spi.sdi = spi_sdi;
	assign spi_sdo = spi.sdo;

	assign charlieplex_o = 0;
	assign charlieplex_oe = 0;

	mInterconnect mint(
		.peri(wbp.mPeri),
		.ctrl(wbc.mCtrl)
	);

	mSpi mspi(
		.wb(wbc.mCtrl),
		.spi(spi.mPeri)
	);

//	mBlinkenlight mBlinkenlight(
//		.wb(wbc.mCtrl),
//		.blinkenlight(debug)
//	);

//	mCharlieplex#( .pCpuHz(pCpuHz) ) wb0(
//		.wb(wbp.mPeri),
//		.charlieplex_o(charlieplex_o),
//		.charlieplex_oe(charlieplex_oe)
//	);

	assign rgb = { counter, 2'b00 };

//	mRgb wb0(
//		.wb(wbp.mPeri),
//		.rgb(rgb)
//	);

	mDebug wb0(
		.wb(wbp.mPeri),
		.debug(debug)
	);

	always_ff @(posedge clk) begin
		rst_n <= 1;
		counter <= !counter;
	end

endmodule
