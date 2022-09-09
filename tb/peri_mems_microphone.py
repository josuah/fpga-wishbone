import random
import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from tb.driver.wishbone import WishboneDriver

@cocotb.test(timeout_time=100000, timeout_unit="ns")
async def test_peri_mems_microphone(dut):
    """
    Send data synchronised to the clock coming out of the device.
    """
    for i in range(4):
        await run_peri_mems_microphone(dut, 4)

async def drive_mic(log, mic_clk, mic_data, nsamples):
    """
    Set mic_data to a random value at every mic_clk tick, and yield them as byte.
    """
    sample = 0
    i = 0
    while nsamples > 0:
        await RisingEdge(mic_clk)
        mic_data.value = random.getrandbits(1)
        sample += mic_data.value
        i += 1
        if i == 256:
            log.debug(f"yielding {sample}")
            yield sample
            sample = 0
            nsamples -= 1
            i = 0

async def run_peri_mems_microphone(dut, nsamples):

    log = dut._log
    irq = dut.irq_o
    mic_clk = dut.mic_clk_o
    mic_data = dut.mic_data_i

    wb = WishboneDriver(log, dut.clk_i, dut.rst_ni, dut.wb_we_i, dut.wb_adr_i,
        dut.wb_dat_i, dut.wb_stb_i, dut.wb_ack_o, dut.wb_dat_o)
    await wb.reset()

    i = 0
    async for mic_byte in drive_mic(log, dut.mic_clk_o, dut.mic_data_i, nsamples):
        log.debug("waiting dut.irq_o")
        wb_byte = await wb.read(0)

        log.info(f"{wb_byte} =?= {mic_byte}")
        assert mic_byte == wb_byte
        if i == 10:
            break
        i += 1
        await RisingEdge(dut.irq_o)
