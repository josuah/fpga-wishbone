// Wishbone B4 Pipelined interconnect module
//
// Designed for a single master such as a MCU, and multiple
// peripherals. This is the place where addressing of slaves is
// configured.
//
// The input and outputs are looking to be reversed, it is due
// to this piece of code looking from the inside of the crossbar
// so we receive master's output and send to slave's input

module wbx_1master #(
	parameter PERIPH_NUM = 0
) (
	// wishbone b4 pipelined
	input wire wb_clk_i,
	input wire wb_rst_i,

	// wishbone b4 pipelined slaves
	output wire wbs_cyc_i,
	output wire wbs_stb_i,
	output wire wbs_we_i,
	output wire [3:0] wbs_adr_i,
	output wire [3:0] wbs_sel_i,
	output wire [31:0] wbs_dat_i,
	input wire [PERIPH_NUM*32-1:0] wbs_dat_o,
	input wire [PERIPH_NUM-1:0] wbs_stall_o,
	input wire [PERIPH_NUM-1:0] wbs_ack_o,

	// wishbone b4 pipelined master
	input wire wbm_cyc_o,
	input wire wbm_stb_o,
	input wire wbm_we_o,
	input wire [31:0] wbm_adr_o,
	input wire [3:0] wbm_sel_o,
	input wire [31:0] wbm_dat_o,
	output wire [31:0] wbm_dat_i,
	output wire wbm_stall_i,
	output wire wbm_ack_i

);
	localparam CPU_CLK_HZ = 48_000_000;

	wire unused = &{
		wb_clk_i, wb_rst_i,
		wbs_dat_o, wbs_stall_o, wbs_ack_o,
		wbm_cyc_o, wbm_stb_o, wbm_we_o, wbm_adr_o, wbm_sel_o, wbm_dat_o
	};

	assign {
		wbs_cyc_i, wbs_stb_i, wbs_we_i, wbs_adr_i, wbs_sel_i, wbs_dat_i,
		wbm_dat_i, wbm_stall_i, wbm_ack_i
	} = 0;

endmodule
