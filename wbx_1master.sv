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
	// Wishbone B4 Pipelined
	input wire wb_clk_i,
	input wire wb_rst_i,

	// Wishbone B4 pipelined slaves
	output wire [PERIPH_NUM-1:0] wbs_cyc_i,
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
	input wire [15:0] wbm_adr_o,
	input wire [3:0] wbm_sel_o,
	input wire [31:0] wbm_dat_o,
	output wire [31:0] wbm_dat_i,
	output wire wbm_stall_i,
	output wire wbm_ack_i
);
	localparam CPU_CLK_HZ = 48_000_000;

        // add persistence to `wbs_adr_i`
	reg [11:0] periph_addr_reg = 0;
	wire [11:0] periph_addr = wbm_cyc_o && wbm_stb_o ? wbm_adr_o[15:4] : periph_addr_reg;
	always @(posedge wb_clk_i)
		periph_addr_reg <= periph_addr;

        // signals from master to slave, that are just direct wires, controlled
	// by CYC signal that tells whether to react or not to them
	assign wbs_cyc_i = wbm_cyc_o << periph_addr_reg;
	assign wbs_stb_i = wbm_stb_o;
	assign wbs_we_i = wbm_we_o;
	assign wbs_adr_i = wbm_adr_o[3:0];
	assign wbs_sel_i = wbm_sel_o;
	assign wbs_dat_i = wbm_dat_o;

	// selecting which peripheral's signal to transmit depending on address
	always_comb begin
		wbm_dat_i = wbs_dat_o >> periph_addr * 32;
		wbm_ack_i = wbs_ack_o >> periph_addr;
		wbm_stall_i = wbs_stall_o >> periph_addr;
	end

	always @(posedge wb_clk_i) begin
		if (wb_rst_i)
			periph_addr_reg <= 0;
	end

endmodule
