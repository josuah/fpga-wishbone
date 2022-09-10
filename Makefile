ICEPACK = icepack
ICEPROG = iceprog
VERILATOR = verilator -Wall -DSIMULATION --sv
NEXTPNR = nextpnr-ice40 --randomize-seed --up5k --package sg48
YOSYS = yosys
MAKE = gmake

COCOTB = ${MAKE} -f "$$(cocotb-config --makefiles)/Makefile.sim" MAKE="${MAKE}" \
  SIM="verilator" EXTRA_ARGS="--trace" TOPLEVEL_LANG="verilog"
COCOTB_FLAGS = TOPLEVEL="${*F}" MODULE="tb.${*F}" SIM_BUILD="$*.d" \
  COCOTB_RESULTS_FILE="$*.xml"

RTL = rtl/clock_domain_crossing.sv rtl/ctrl_async.sv rtl/ctrl_spi.sv \
  rtl/ctrl_sync.sv rtl/ctrl_uart.sv rtl/peri_charlieplex.sv \
  rtl/peri_debug.sv rtl/peri_draw_line.sv rtl/peri_mems_microphone.sv \
  rtl/peri_pdm_channel.sv rtl/peri_pwm_channel.sv rtl/peri_rgb_led.sv \
  rtl/register_bank.sv rtl/spi_rx.sv rtl/spi_tx.sv rtl/top.sv rtl/uart_rx.sv \
  rtl/uart_tx.sv

all: ice40.bit

clean:
	rm -f *.log *.json *.asc *.bit *.hex */*.dot */*.pdf
	rm -rf tb/*.xml tb/*.d

lint:
	${VERILATOR} --lint-only --top-module top ${RTL}

flash: ice40.bit
	${ICEPROG} -d i:0x0403:0x6014:0 ice40.bit

sim: tb/top.xml
tb/top.xml: tb/top.py ${RTL}
	${COCOTB} ${COCOTB_FLAGS} VERILOG_SOURCES="${RTL}"

test: tb/peri_mems_microphone.xml
tb/peri_mems_microphone.xml: tb/peri_pdm_channel.py rtl/peri_mems_microphone.sv
	${COCOTB} ${COCOTB_FLAGS} VERILOG_SOURCES="rtl/peri_mems_microphone.sv"

test: tb/peri_pdm_channel.xml
tb/peri_pdm_channel.xml: tb/peri_pdm_channel.py rtl/peri_pdm_channel.sv
	${COCOTB} ${COCOTB_FLAGS} VERILOG_SOURCES="rtl/peri_pdm_channel.sv"

test: tb/register_bank.xml
tb/register_bank.xml: tb/register_bank.py rtl/register_bank.sv
	${COCOTB} ${COCOTB_FLAGS} VERILOG_SOURCES="rtl/register_bank.sv"

test: tb/uart_tx.xml
tb/uart_tx.xml: tb/uart_tx.py rtl/uart_tx.sv
	${COCOTB} ${COCOTB_FLAGS} VERILOG_SOURCES="rtl/uart_tx.sv"

.SUFFIXES: .sv .elf .vcd .json .asc .bit .dfu .hex .dot .pdf .py .xml

.sv.json:
	${YOSYS} -p "read_verilog -sv $< ${RTL}; synth_ice40 -top $* -json $@" >$*.yosys.log
	@grep -i -e warn -e error $*.yosys.log

.elf.vcd:
	./$< >$@

.json.asc:
	${NEXTPNR} -q -l $*.nextpnr.log --pcf ports.pcf --json $< --asc $@
	@grep -i -e warn -e error $*.nextpnr.log

.asc.bit:
	${ICEPACK} $< $@

.bit.dfu:
	cp $< $@
	dfu-suffix -v 1209 -p 70b1 -a $@

.sv.dot:
	${YOSYS} -p "read_verilog -sv $<; show -format dot -prefix $*"

.dot.pdf:
	dot -Tpdf $< >$@

.py.xml:
	mv dump.vcd $*.d/dump.vcd
