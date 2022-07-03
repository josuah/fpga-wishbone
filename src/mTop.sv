`default_nettype none

module mTop #(
	parameter TICKS_PER_BAUD = 4,
	parameter WISHBONE_PERIPH_NUM = 1,
	parameter CPU_CLK_HZ = 48_000_000
) (
	// System Clock
	input wire clk,

        // SPI Slave I/O
        input wire spi_sck,
        input wire spi_csn,
        input wire spi_sdi,
        output wire spi_sdo,

	// CharliePlexed LED Matrix Screen
	output wire [6:0] charlie7x5_o,
	output wire [6:0] charlie7x5_oe,

	// RGB LED
	output wire led_r,
	output wire led_g,
	output wire led_b,

	// Debug LEDs
	output wire [7:0] debug
);
	reg rst_n = 0;
	reg counter = 0;
	wire rst = !rst_n;
	// slave wires
	wire wbs_stb_i, wbs_we_i;
	wire [31:0] wbs_dat_i;
	wire [3:0] wbs_adr_i;
	wire [32*WISHBONE_PERIPH_NUM-1:0] wbs_dat_o;
	wire [WISHBONE_PERIPH_NUM-1:0] wbs_ack_o;
	// master wires
        wire wbm_stb_o, wbm_we_o, wbm_ack_i;
	wire [15:0] wbm_adr_o;
	wire [31:0] wbm_dat_o, wbm_dat_i;

	wishbone wb0 (clk, rst);

	assign charlie7x5_o = 0;
	assign charlie7x5_oe = 0;

	wbx_1master #(
		.PERIPH_NUM(WISHBONE_PERIPH_NUM)
	) wbx_1master (
		.clk(clk),
		.rst(rst),

		// plug all the slaves
		.wbs_stb_i(wbs_stb_i),
		.wbs_we_i(wbs_we_i),
		.wbs_adr_i(wbs_adr_i),
		.wbs_dat_i(wbs_dat_i),
		.wbs_dat_o(wbs_dat_o),
		.wbs_ack_o(wbs_ack_o),

		// plug the single master
		.wbm_stb_o(wbm_stb_o),
		.wbm_we_o(wbm_we_o),
		.wbm_adr_o(wbm_adr_o),
		.wbm_dat_o(wbm_dat_o),
		.wbm_dat_i(wbm_dat_i),
		.wbm_ack_i(wbm_ack_i)
	);

	wbm_spi wbm_spi (
		.wb(wb0),
		.spi_sck(spi_sck),
		.spi_csn(spi_csn),
		.spi_sdi(spi_sdi),
		.spi_sdo(spi_sdo)
	);

	wbm_blinkenlight wbm_blinkenlight (
		.wb(wb0),
		.blinkenlight(debug)
	);

//	wbs_charlie7x5 #(
//		.WB_CLK_HZ(CPU_CLK_HZ)
//	) wbs0 (
//		.wb(wb0),
//		.charlie7x5_o(charlie7x5_o),
//		.charlie7x5_oe(charlie7x5_oe)
//	);

//	assign { led_r, led_g, led_b } = { counter, 2'b00 };

	wbs_rgb wbs0 (
		.wb(wb0),
		.led_r(led_r),
		.led_g(led_g),
		.led_b(led_b)
	);

//	wbs_debug wbs0 (
//		.wb(wb0),
//		.debug(debug)
//	);

	always_ff @(posedge clk) begin
		rst_n <= 1;
		counter <= !counter;
	end

endmodule
