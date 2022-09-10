/*
 * issue requests to a wishbone b4 classic peripheral
 */
static inline uint32_t
wbp_read(uint32_t addr)
{
	vsim->wb_stb_i = 1;
	vsim->wb_we_i = 0;
	vsim->wb_adr_i = addr;
	tick(v);

	while (vsim->wb_stall_o) tick(v);
	vsim->wb_stb_i = 0;
	vsim->wb_we_i = 0;
	while (!vsim->wb_ack_o) tick(v);

	return 0; //vsim->wb_dat_o;
}

/*
 * wishbone b4 peripheral write request in classic mode
 */
static inline void
wbp_queue_write(wb_addr_t addr, wb_addr_t data)
{
	vsim->wb_stb_i = 1;
	vsim->wb_we_i = 1;
	vsim->wb_adr_i = addr;
	vsim->wb_dat_i = data;
}

static inline simulation_wire_t
wbp_wait_ack()
{
	simulation_eval();
	while (vsim->wb_ack_o == 0) {
		simulation_tick();
	}

	return vsim->wb_data_o;
}

	while (!vsim->wb_ack_o)
		simulation_tick();

	while (vsim->wb_stall_o) tick(v);
	vsim->wb_stb_i = 0;
	vsim->wb_we_i = 0;
	while (!vsim->wb_ack_o) tick(v);
}
