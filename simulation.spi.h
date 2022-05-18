struct spi_buf {
	uint8_t *buf, byte;
	size_t len;
};

struct spi {
	struct spi_buf tx, rx;
	uint8_t bits_sent;
} spi;

static void
spi_tick_posedge(uint64_t ns)
{
	vsim->spi_sck = 1;
	if (spi.tx.len > 0)
		vsim->spi_sdi = spi.tx.byte & 0x01;
	simulation_eval(ns);

	if (spi.rx.len > 0)
		spi.rx.byte = spi.rx.byte << 1 | vsim->spi_sdo;
	if (spi.tx.len > 0)
		spi.tx.byte = spi.tx.byte >> 1;
}

static void
spi_tick_negedge(uint64_t ns)
{
	vsim->spi_sck = 0;
	simulation_eval(ns);

	if (++spi.bits_sent == 8) {
		spi.bits_sent = 0;
		if (spi.tx.len > 0)
			spi.tx.len--, spi.tx.buf++;
		if (spi.rx.len > 0)
			spi.rx.len--, spi.rx.buf++;
		if (spi.tx.len > 0)
			spi.tx.byte = *spi.tx.buf;
		if (spi.rx.len > 0)
			spi.rx.byte = *spi.rx.buf;
	}
}

static int
spi_queue_write(char const *buf, size_t len)
{
	if (spi.tx.len > 0 || len == 0)
		return -1;
	spi.tx.buf = (uint8_t *)buf;
	spi.tx.len = len;
	spi.tx.byte = *buf;
	return 0;
}

static int
spi_queue_read(char *buf, size_t len)
{
	if (spi.rx.len > 0 || len == 0)
		return -1;
	spi.rx.buf = (uint8_t *)buf;
	spi.rx.len = len;
	spi.rx.byte = *buf;
	return 0;
}
