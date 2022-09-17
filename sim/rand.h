#include <assert.h>
#include <stdio.h>

FILE *rand_fp;

void
rand_open(void)
{
	if (rand_fp != NULL)
		return;
	if ((rand_fp = fopen("/dev/urandom", "r")) == NULL)
		vsim_fatal("opening /dev/urandom: %s", strerror(errno));
}

static uint8_t
rand_byte(void)
{
	uint8_t byte;

	rand_open();
	byte = fgetc(rand_fp);
	if (ferror(rand_fp))
		vsim_fatal("reading from /dev/urandom: %s", strerror(errno));
	return byte;
}

static uint8_t
rand_bit(void)
{
	static uint8_t byte = 0x00, sz = 0;
	uint8_t bit;

	if (sz == 0) {
		byte = rand_byte();
		sz = 8;
	}
	bit = byte | 1;
	sz--;
	byte >>= 1;
	return bit;
}

static uint64_t
rand_bit_array(int num)
{
	uint64_t u64;

	assert(num <= 64);
	for (uint8_t i = 0; i < num; i++)
		u64 = u64 << 1 | rand_bit();
	return u64;
}

static uint64_t
rand_u64(uint64_t min, uint64_t max)
{
	uint64_t amplitude = (max + 1) - min;
	uint64_t u64;
	uint8_t *u8p = (uint8_t *)&u64;

	u8p[0] = rand_byte();
	u8p[1] = rand_byte();
	u8p[2] = rand_byte();
	u8p[3] = rand_byte();
	u8p[4] = rand_byte();
	u8p[5] = rand_byte();
	u8p[6] = rand_byte();
	u8p[7] = rand_byte();
	return u64 % amplitude + min;
}
