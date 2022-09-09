import random
import cocotb
from cocotb.triggers import RisingEdge
from tb.driver.wishbone import WishboneDriver

@cocotb.test(timeout_time=1000000, timeout_unit="ns")
async def test_register_bank(dut):
    """
    Set and read registers randomly.
    """
    for i in range(4):
        await run_register_bank(dut)

async def register_set(log, wb, mirror, addr, data):
    """
    set a register to the given value
    """
    log.debug(f"addr={addr} data={data}")
    mirror[addr] = data
    for i in range(random.randint(0, 3)):
        await RisingEdge(wb.clk_i)
    await wb.write(addr, data)

async def register_check(log, wb, mirror, nb):
    """
    Read all registers and check them against the mirror.
    """
    for addr in range(nb):
        for i in range(random.randint(0, 3)):
            await RisingEdge(wb.clk_i)
        mirror_byte = mirror[addr] if addr in mirror else 0
        reg_byte = await wb.read(addr)
        log.info(f"[{addr}] {reg_byte} =?= {mirror_byte}")
        assert(reg_byte == mirror_byte)

async def run_register_bank(dut, RegsNb=3, DataSz=8):
    log = dut._log
    mirror = {}

    wb = WishboneDriver(dut._log, dut.clk_i, dut.rst_ni, dut.wb_we_i, dut.wb_adr_i,
        dut.wb_dat_i, dut.wb_stb_i, dut.wb_ack_o, dut.wb_dat_o)
    await wb.reset()

    for i in range(50):
        addr = random.randint(0, RegsNb - 1)
        data = random.getrandbits(DataSz)
        await register_set(log, wb, mirror, addr, data)
        await register_check(log, wb, mirror, RegsNb)
