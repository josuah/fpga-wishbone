MAKE = gmake
COCOTB = ${MAKE} -f "$$(cocotb-config --makefiles)/Makefile.sim" MAKE="${MAKE}" \
  SIM="verilator" EXTRA_ARGS="--trace" TOPLEVEL_LANG="verilog"
COCOTB_FLAGS = TOPLEVEL="${*F}" MODULE="${*F}" SIM_BUILD="$*.d" \
  COCOTB_RESULTS_FILE="$*.xml"

.SUFFIXES: .py .xml

all: top.xml
top = ../rtl/clock_domain_crossing.sv ../rtl/ctrl_async.sv \
../rtl/ctrl_spi.sv ../rtl/ctrl_sync.sv ../rtl/ctrl_uart.sv \
../rtl/peri_charlieplex.sv ../rtl/peri_debug.sv ../rtl/peri_draw_line.sv \
../rtl/peri_mems_microphone.sv ../rtl/peri_pdm_channel.sv \
../rtl/peri_pwm_channel.sv ../rtl/peri_rgb_led.sv ../rtl/register_bank.sv \
../rtl/spi_rx.sv ../rtl/spi_tx.sv ../rtl/top.sv ../rtl/uart_rx.sv \
../rtl/uart_tx.sv
top.xml: ${top}
	${COCOTB} ${COCOTB_FLAGS} VERILOG_SOURCES="${top}"

all: peri_mems_microphone.xml
peri_mems_microphone = ../rtl/peri_mems_microphone.sv
peri_mems_microphone.xml: ${peri_mems_microphone}
	${COCOTB} ${COCOTB_FLAGS} VERILOG_SOURCES="${peri_mems_microphone}"

all: peri_pdm_channel.xml
peri_pdm_channel = ../rtl/peri_pdm_channel.sv
peri_pdm_channel.xml: ${peri_pdm_channel}
	${COCOTB} ${COCOTB_FLAGS} VERILOG_SOURCES="${peri_pdm_channel}"

all: register_bank.xml
register_bank = ../rtl/register_bank.sv
register_bank.xml: ${register_bank}
	${COCOTB} ${COCOTB_FLAGS} VERILOG_SOURCES="${register_bank}"

all: uart_tx.xml
uart_tx = ../rtl/uart_tx.sv
uart_tx.xml: ${uart_tx}
	${COCOTB} ${COCOTB_FLAGS} VERILOG_SOURCES="${uart_tx}"

clean:
	rm -rf *.xml *.d
