import random
import cocotb
from cocotb.triggers import RisingEdge
from cocotb.triggers import FallingEdge
from cocotb.clock import Clock
from tb.driver.wishbone import WishboneDriver

@cocotb.test(timeout_time=100000, timeout_unit="ns")
async def test_peri_mems_microphone(dut):
    """
    Send data synchronised to the clock coming out of the device.
    """
    for i in range(10):
        await run_peri_mems_microphone(dut)

async def drive_mic(log, mic_clk, mic_data):
    """
    Set mic_data to a random value at every mic_clk tick, and yield them as byte.
    """
    log.info("entered drive_mic func")
    byte = 0
    i = 0
    while True:
        await RisingEdge(mic_clk)
        mic_data.value = random.getrandbits(1)
        byte += mic_data.value
        i += 1
        if i == 256:
            log.info(f"yielding {byte}")
            yield byte
            byte = 0
            i = 0

async def run_peri_mems_microphone(dut):
    log = dut._log

    # driver
    wb = WishboneDriver(dut._log, dut.clk_i, dut.rst_ni, dut.wb_we_i, dut.wb_adr_i,
        dut.wb_dat_i, dut.wb_stb_i, dut.wb_ack_o, dut.wb_dat_o)
    irq = dut.irq_o
    mic_clk = dut.mic_clk_o
    mic_data = dut.mic_data_i
    log.debug("run_peri_mems_microphone: waiting random amount of clock edges")
    for i in range(random.randint(0, 50)):
        log.debug(f"run_peri_mems_microphone: waiting edge {i}")
        await FallingEdge(dut.clk_i)
    log.debug(f"run_peri_mems_microphone: issuing a reset")
    await wb.reset()

    # monitor
    i = 0
    log.info("entering async for")
    async for mic_byte in drive_mic(log, dut.mic_clk_o, dut.mic_data_i):
        log.info("waiting dut.irq_o")
        await RisingEdge(dut.irq_o)
        wb_byte = wb.read(0)
        log.info(f"{wb_byte} =?= {mic_byte}")
        assert mic_byte == wb_byte
        if i == 10:
            break
        i += 1
