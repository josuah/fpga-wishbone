import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock

@cocotb.test(timeout_time=1000, timeout_unit="us")
async def test_peri_pdm_channel(dut):
    cocotb.start_soon(Clock(dut.clk_i, 1, "ns").start())

    await RisingEdge(dut.clk_i)
    dut.rst_ni.value = 0
    await RisingEdge(dut.clk_i)
    dut.rst_ni.value = 1
    await RisingEdge(dut.clk_i)

    for i in range(10000):
        await RisingEdge(dut.clk_i)
