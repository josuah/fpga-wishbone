/*
 * Maximal size of the address bus, may be less in the verilog implementation.
 */
typedef uint64_t wishbone_addr_t;

/*
 * Maximal size of the data bus (in or out), may be less in the verilog implementation.
 */
typedef uint64_t wishbone_data_t;

enum wishbone_peri_state {
	WISHBONE_PERI_STATE_DONE = 1,
	WISHBONE_PERI_STATE_IDLE = 0,
	WISHBONE_PERI_STATE_SEND_REQUEST = 2,
	WISHBONE_PERI_STATE_WAIT_ACK,
};

struct wishbone_peri {
	enum wishbone_peri_state state;
	uint8_t wb_we_o;
	uint8_t wb_sel_o;
	wishbone_addr_t wb_adr_o;
	wishbone_data_t wb_dat_o;
	wishbone_data_t wb_dat_i;
};

static inline struct wishbone_peri wishbone_peri;

static inline int
wishbone_peri_posedge(wishbone_data_t *data)
{
	switch (wishbone_peri.state) {
	case WISHBONE_PERI_STATE_DONE:
		vsim->wb_stb_i = 0;
		vsim_eval();
		wishbone_peri.state = WISHBONE_PERI_STATE_IDLE;
		/* fallthrough */
	case WISHBONE_PERI_STATE_IDLE:
		break;
	case WISHBONE_PERI_STATE_SEND_REQUEST:
		vsim->wb_stb_i = 1;
		vsim->wb_we_i = wishbone_peri.wb_we_i;
		vsim->wb_adr_i = wishbone_peri.wb_adr_i;
		vsim->wb_dat_i = wishbone_peri.wb_dat_i;
		wishbone_peri.state = WISHBONE_PERI_STATE_WAIT_ACK;
		return wishbone_peri_posedge(data);
	case WISHBONE_PERI_STATE_WAIT_ACK:
		if (vsim->wb_ack_o) {
			*data = wishbone_peri
			wishbone_peri.state = WISHBONE_PERI_STATE_DONE;
			return 1;
		}
		break;
	}
	return 0;
}

static inline void
wishbone_peri_queue_read(wishbone_addr_t addr)
{
	vsim->wb_we_i = 0;
	vsim->wb_adr_i = addr;
	wishbone_peri.state = WISHBONE_PERI_STATE_SEND_REQUEST;
}

static inline void
wishbone_peri_queue_write(wishbone_addr_t addr, wishbone_data_t data)
{
	vsim->wb_we_i = 1;
	vsim->wb_adr_i = addr;
	vsim->wb_dat_i = data;
	wishbone_peri.state = WISHBONE_PERI_STATE_SEND_REQUEST;
}
