import random
import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from tb.driver.wishbone import WishboneDriver

@cocotb.test(timeout_time=1000, timeout_unit="us")
async def test_peri_pdm_channel(dut):
    for i in range(100000):
        await RisingEdge(dut.clk_i)
