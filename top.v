`default_nettype none

module top #(
	parameter TICKS_PER_BAUD = 4,
	parameter WISHBONE_PERIPH_NUM = 1,
	parameter CPU_CLK_HZ = 48_000_000
) (
	input wire clk,

        // SPI slave I/O
        input wire spi_sck,
        input wire spi_csn,
        input wire spi_sdi,
        output wire spi_sdo,

	// charlie7x5
	output wire [6:0] charlie7x5_o,
	output wire [6:0] charlie7x5_oe,

	// debug
	output wire gpio_25,
	output wire gpio_26
);
	reg rst_n = 0;

	wire rst = !rst_n;

	always @(posedge clk)
		rst_n <= 1;

        wire wb_clk_i = clk, wb_rst_i = rst;

	// Interconnect //

	// slave wires
	wire wbs_stb_i, wbs_we_i;
	wire [31:0] wbs_dat_i;
	wire [3:0] wbs_adr_i;
	wire [4*WISHBONE_PERIPH_NUM-1:0] wbs_sel_i;
	wire [32*WISHBONE_PERIPH_NUM-1:0] wbs_dat_o;
	wire [WISHBONE_PERIPH_NUM-1:0] wbs_stall_o, wbs_ack_o, wbs_cyc_i;

	// master wires
        wire wbm_stb_o, wbm_we_o, wbm_stall_i, wbm_ack_i, wbm_cyc_o;
	wire [3:0] wbm_sel_o;
	wire [15:0] wbm_adr_o;
	wire [31:0] wbm_dat_o, wbm_dat_i;

	wbx_1master #(
		.PERIPH_NUM(WISHBONE_PERIPH_NUM)
	) wbx_1master (
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),

		// plug all the slaves
		.wbs_cyc_i(wbs_cyc_i),
		.wbs_stb_i(wbs_stb_i),
		.wbs_we_i(wbs_we_i),
		.wbs_adr_i(wbs_adr_i),
		.wbs_sel_i(wbs_sel_i),
		.wbs_dat_i(wbs_dat_i),
		.wbs_dat_o(wbs_dat_o),
		.wbs_stall_o(wbs_stall_o),
		.wbs_ack_o(wbs_ack_o),

		// plug the single master
		.wbm_cyc_o(wbm_cyc_o),
		.wbm_stb_o(wbm_stb_o),
		.wbm_we_o(wbm_we_o),
		.wbm_adr_o(wbm_adr_o),
		.wbm_sel_o(wbm_sel_o),
		.wbm_dat_o(wbm_dat_o),
		.wbm_dat_i(wbm_dat_i),
		.wbm_stall_i(wbm_stall_i),
		.wbm_ack_i(wbm_ack_i)
	);

	// Master //

	wbm_spi wbm_spi (
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_cyc_o(wbm_cyc_o),
		.wb_stb_o(wbm_stb_o),
		.wb_we_o(wbm_we_o),
		.wb_sel_o(wbm_sel_o),
		.wb_dat_o(wbm_dat_o),
		.wb_adr_o(wbm_adr_o),
		.wb_dat_i(wbm_dat_i),
		.wb_stall_i(wbm_stall_i),
		.wb_ack_i(wbm_ack_i),
		.spi_sck(spi_sck),
		.spi_csn(spi_csn),
		.spi_sdi(spi_sdi),
		.spi_sdo(spi_sdo),
		.gpio_25(gpio_25),
		.gpio_26(gpio_26)
	);

	// Peripherals //

`define WISHBONE_B4_PIPELINED(ID) \
	.wb_clk_i(wb_clk_i), \
	.wb_rst_i(wb_rst_i), \
	.wb_cyc_i(wbs_cyc_i[ID]), \
	.wb_stb_i(wbs_stb_i), \
	.wb_we_i(wbs_we_i), \
	.wb_adr_i(wbs_adr_i), \
	.wb_sel_i(wbs_sel_i),  \
	.wb_dat_i(wbs_dat_i), \
	.wb_dat_o(wbs_dat_o[32*(ID+1)-1:32*ID]), \
	.wb_stall_o(wbs_stall_o[ID]), \
	.wb_ack_o(wbs_ack_o[ID])

	wbs_charlie7x5 #(
		.WB_CLK_HZ(CPU_CLK_HZ)
	) wbs0 (
		`WISHBONE_B4_PIPELINED(0),
		.charlie7x5_o(charlie7x5_o),
		.charlie7x5_oe(charlie7x5_oe)
	);

endmodule
