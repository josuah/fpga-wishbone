import cocotb
from cocotb.triggers import FallingEdge
from cocotb.triggers import Timer

class UartTxDriver:
    def __init__(self, log, clk_i, rst_ni, uart_tx_no):
        self.log = log
        self.clk_i = clk_i
        self.rst_ni = rst_ni
        self.uart_tx_no = uart_tx_no

    async def read_bit(self, baudrate=9600):
        await Timer(int(1000000000 / baudrate / 2), units="ns")
        bit = self.uart_tx_no.value
        await Timer(int(1000000000 / baudrate / 2), units="ns")
        return bit

    async def read_byte(self, baudrate=9600):
        self.log.debug(f"UartTxDriver: read_byte: baudrate={baudrate}")
        byte = 0
        # start bit
        await FallingEdge(self.uart_tx_no)
        # data bits
        byte |= await self.read_bit(baudrate=baudrate) << 0
        byte |= await self.read_bit(baudrate=baudrate) << 1
        byte |= await self.read_bit(baudrate=baudrate) << 2
        byte |= await self.read_bit(baudrate=baudrate) << 3
        byte |= await self.read_bit(baudrate=baudrate) << 4
        byte |= await self.read_bit(baudrate=baudrate) << 5
        byte |= await self.read_bit(baudrate=baudrate) << 6
        byte |= await self.read_bit(baudrate=baudrate) << 7
        # stop bits
        await self.read_bit(baudrate=baudrate)
        await self.read_bit(baudrate=baudrate)
        return byte

    async def read(self, num, baudrate=9600):
        for i in range(num):
            yield await self.read_byte(baudrate=baudrate)

class UartRxDriver:
    def __init__(self, log, clk_i, rst_ni, uart_rx_ni):
        self.log = log
        self.clk_i = clk_i
        self.rst_ni = rst_ni
        self.uart_rx_ni = uart_rx_ni
        self.uart_rx_ni.value = 1

    async def write_bit(self, bit, baudrate=9600):
        self.uart_rx_ni.value = bit
        await Timer(1 / baudrate, units="s")

    async def write_byte(self, byte, baudrate=9600):
        self.log.debug(f"UartRxDriver: write_byte: byte={byte} baudrate={baudrate}")
        # start bit
        await self.write_bit(0, baudrate=baudrate)
        # data bits
        await self.write_bit((byte >> 0) & 1, baudrate=baudrate)
        await self.write_bit((byte >> 1) & 1, baudrate=baudrate)
        await self.write_bit((byte >> 2) & 1, baudrate=baudrate)
        await self.write_bit((byte >> 3) & 1, baudrate=baudrate)
        await self.write_bit((byte >> 4) & 1, baudrate=baudrate)
        await self.write_bit((byte >> 5) & 1, baudrate=baudrate)
        await self.write_bit((byte >> 6) & 1, baudrate=baudrate)
        await self.write_bit((byte >> 7) & 1, baudrate=baudrate)
        # stop bits
        await self.write_bit(1, baudrate=baudrate)
        await self.write_bit(1, baudrate=baudrate)

    async def write(self, str, baudrate=9600):
        for c in str:
            self.write_byte(ord(c), baudrate=baudrate)
