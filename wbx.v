// Wishbone B4 Pipelined interconnect module
//
// Designed for a single master such as a MCU, and multiple
// peripherals. This is the place where addressing of slaves is
// configured.

module #(
) wbx (
	
);

	wbs_charlie7x5 #(
		.WB_CLK_HZ(CPU_CLK_HZ)
	) charlie7x5 (
		.wbs_clk_i(clk),
		.wbs_rst_i(rst),
		.wbs_cyc_i(
			charlie7x5_state >= CHARLIE7X5_STATE_WAIT_STALL
		&&      charlie7x5_state <= CHARLIE7X5_STATE_WAIT_ACK
		),
		.wbs_stb_i(
			charlie7x5_state == CHARLIE7X5_STATE_WAIT_STALL
		),
		.wbs_we_i(1),
		.wbs_adr_i(charlie7x5_addr),
		.wbs_dat_i(
			charlie7x5_addr == 0 ? 32'b1_0_0_0_0_0_1 :
			charlie7x5_addr == 1 ? 32'b0_1_0_0_0_0_1 :
			charlie7x5_addr == 2 ? 32'b0_0_1_1_1_1_0 :
			charlie7x5_addr == 3 ? 32'b0_1_0_0_0_0_1 :
			charlie7x5_addr == 4 ? 32'b1_0_0_0_0_0_1 :
			32'b1111111
		),
		.wbs_dat_o(charlie7x5_dat_o),
		.wbs_stall_o(charlie7x5_stall_o),
		.wbs_ack_o(charlie7x5_ack_o),
		.charlie7x5_oe(charlie7x5_oe),
		.charlie7x5_o(charlie7x5_o)
	);


endmodule
