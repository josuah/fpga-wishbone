struct spi_buf {
	uint8_t *buf;
	size_t len;
};

struct spi {
	struct simulation *sim;
	struct spi_buf tx, rx;
	uint8_t bits_sent;
};

static inline void
spi_init(struct spi *spi, struct simulation *sim)
{
	memset(spi, 0, sizeof *spi);
	spi->sim = sim;
}

static void
spi_tick_posedge(struct spi *spi, uint64_t ns)
{
	spi->sim->v->spi_sck = 1;
	if (spi->tx.len > 0)
		spi->sim->v->spi_sdi = *spi->tx.buf & 0x01;
	simulation_eval(spi->sim, ns);

	if (spi->rx.len > 0)
		*spi->rx.buf = *spi->rx.buf << 1 | spi->sim->v->spi_sdo;
	if (spi->tx.len > 0)
		*spi->tx.buf = *spi->tx.buf >> 1;
}

static void
spi_tick_negedge(struct spi *spi, uint64_t ns)
{
	spi->sim->v->spi_sck = 0;
	simulation_eval(spi->sim, ns);

	if (++spi->bits_sent == 8) {
		spi->bits_sent = 0;
		if (spi->tx.len > 0)
			spi->tx.len--, spi->tx.buf++;
		if (spi->rx.len > 0)
			spi->rx.len--, spi->rx.buf++;
	}
}

static int
spi_queue_write(struct spi *spi, char const *buf, size_t len)
{
	if (spi->tx.len > 0)
		return -1;

	spi->tx.buf = (uint8_t *)buf;
	spi->tx.len = len;

	return 0;
}

static int
spi_queue_read(struct spi *spi, char *buf, size_t len)
{
	if (spi->rx.len > 0)
		return -1;

	spi->rx.buf = (uint8_t *)buf;
	spi->rx.len = len;

	return 0;
}
