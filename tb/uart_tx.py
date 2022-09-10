import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from tb.driver.uart import UartTxDriver

@cocotb.test(timeout_time=1000000, timeout_unit="ns")
async def test_uart_tx(dut):
    """
    Send data from wishbone, collect it from UART
    """
    for i in range(6):
        await run_uart_tx(dut)

async def mod_write(dut, data):
    dut.tx_data_i.value = data
    dut.tx_stb_i.value = 1
    await RisingEdge(dut.clk_i)

async def run_uart_tx(dut, RegsNb=3, DataSz=8):
    log = dut._log

    uart = UartTxDriver(dut._log, dut.clk_i, dut.rst_ni, dut.uart_tx_no)

    log.debug("starting the clock")
    cocotb.start_soon(Clock(dut.clk_i, 1, "ns").start())

    log.debug("issuing a reset")
    await RisingEdge(dut.clk_i)
    dut.rst_ni.value = 0
    await RisingEdge(dut.clk_i)
    dut.rst_ni.value = 1
    await RisingEdge(dut.clk_i)

    for i in range(random.randint(0, 2)):
        await RisingEdge(dut.clk_i)

    mod_byte = random.randint(0, 255)
    await mod_write(dut, mod_byte)
    async for uart_byte in uart.read(50):
        log.info(f"mod_byte={mod_byte} =?= uart_byte={uart_byte}")
        assert(mod_byte == uart_byte)
        mod_byte = random.randint(0, 255)
        mod_write(dut, mod_byte)
