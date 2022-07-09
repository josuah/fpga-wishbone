`default_nettype none

module mTopLevel(
//	parameter pCpuHz = 48_000_000
//)(
	input	logic clk,
	input	logic spi_sck,
	input	logic spi_csn,
	input	logic spi_sdi,
	output	logic spi_sdo,
	output	logic[6:0] charlieplex_o, charlieplex_oe,
	output	logic[2:0] rgb,
	output	logic[7:0] debug
);
	logic rst_n = 0;
	logic rst = !rst_n;

	iSpi_Ctrl spi_c;
	iSpi_Peri spi_p;

	iWishbone_Ctrl wbc_c;
	iWishbone_Peri wbc_p;

	iWishbone_Ctrl wb0_c;
	iWishbone_Peri wb0_p;

	assign charlieplex_o = 0;
	assign charlieplex_oe = 0;

	assign spi_sdo = spi_p.dat;
	assign spi_c.dat = spi_sdi;
	assign spi_c.sck = spi_sck;
	assign spi_c.csn = spi_csn;

//	assign rgb = {3'b100};

	mSpi ms(
		.clk, .rst, .wb_p(wbc_p), .wb_c(wbc_c),
		.spi_p, .spi_c, .debug
	);

//	mBlinkenLight mbl(
//		.clk, .rst, .wb_c, .wb_p,
//		.blinkenlights(debug)
//	);

	mRgbLed mp0(
		.clk, .rst, .wb_p(wb0_p), .wb_c(wb0_c),
		.rgb(rgb)
	);

//	mDebug mp1(
//		.clk, .rst, .wb_p(wb0_p), .wb_p(wb0_c),
//		.debug(debug)
//	);

//	mCharlieplex#(.pCpuHz) wb2(
//		.clk, .rst, .wb_p(wb0_p), .wb_p(wb0_c),
//		.charlieplex_o, .charlieplex_oe
//	);

	mWishboneInterconnect#(.pPeri(1)) mwi(
		.clk, .rst,
		.wbc_p,
		.wbc_c,
		.wbp_p({wb0_p}),
		.wbp_c({wb0_c})
	);

	always_ff @(posedge clk) begin
		rst_n <= 1;
	end
endmodule
