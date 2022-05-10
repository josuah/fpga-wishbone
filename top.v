`default_nettype none

module top #(
	parameter TICKS_PER_BAUD = 4,
	parameter WISHBONE_PERIPH_NUM = 1,
	parameter CPU_CLK_HZ = 48_000_000
) (
	input wire clk,

	// charlie7x5
	output wire [6:0] charlie7x5_o,
	output wire [6:0] charlie7x5_oe
);
	reg rst_n = 0;

	wire rst = !rst_n;
	wire unused = &{ spi_miso };

	always @(posedge clk)
		rst_n <= 1;

        wire wb_clk_i = clk, wb_rst_i = rst;

	// interconnect //

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
	wire [7:0] wbm_adr_o;
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

	// master //

	wire spi_miso;

	wbm_spi wbm_spi (
		.wbm_clk_i(wb_clk_i),
		.wbm_rst_i(wb_rst_i),
		.wbm_cyc_o(wbm_cyc_o),
		.wbm_stb_o(wbm_stb_o),
		.wbm_we_o(wbm_we_o),
		.wbm_sel_o(wbm_sel_o),
		.wbm_dat_o(wbm_dat_o),
		.wbm_adr_o(wbm_adr_o),
		.wbm_dat_i(wbm_dat_i),
		.wbm_stall_i(wbm_stall_i),
		.wbm_ack_i(wbm_ack_i),
		.spi_ss(0),
		.spi_sck(0),
		.spi_mosi(0),
		.spi_miso(spi_miso)
	);

	// slaves //

`define WISHBONE_B4_PIPELINED(ID) \
	.wbs_clk_i(wb_clk_i), \
	.wbs_rst_i(wb_rst_i), \
	.wbs_cyc_i(wbs_cyc_i[ID]), \
	.wbs_stb_i(wbs_stb_i), \
	.wbs_we_i(wbs_we_i), \
	.wbs_adr_i(wbs_adr_i), \
	.wbs_sel_i(wbs_sel_i),  \
	.wbs_dat_i(wbs_dat_i), \
	.wbs_dat_o(wbs_dat_o[32*(ID+1)-1:32*ID]), \
	.wbs_stall_o(wbs_stall_o[ID]), \
	.wbs_ack_o(wbs_ack_o[ID])

	wbs_charlie7x5 #(
		.WB_CLK_HZ(CPU_CLK_HZ)
	) wbs0 (
		`WISHBONE_B4_PIPELINED(0),
		.charlie7x5_o(charlie7x5_o),
		.charlie7x5_oe(charlie7x5_oe)
	);

endmodule
