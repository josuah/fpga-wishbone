CXX = c++ -I${VERILATOR_ROOT}/include
ICEPACK = icepack
ICEPROG = iceprog
MAKE = gmake
VERILATOR = verilator -Wall -DSIMULATION -Irtl --trace --sv
VERILATOR_ROOT = /usr/local/share/verilator
VERILATOR_SRC = ${VERILATOR_ROOT}/include/verilated.cpp ${VERILATOR_ROOT}/include/verilated_vcd_c.cpp
NEXTPNR = nextpnr-ice40 --randomize-seed --up5k --package sg48
YOSYS = yosys
GTKWAVE = gtkwave -CM6

include Makefile.inc

all: board.bit simulation.vcd test

clean:
	rm -rf simulation simulation_*/ *.log *.json *.asc *.bit *.hex *.elf *.d *.vcd
	rm -rf *.dot */*.dot *.pdf */*.pdf

flash: board.bit
	${ICEPROG} -d i:0x0403:0x6014:0 board.bit

wave: simulation.gtkw simulation.vcd
	${GTKWAVE} -a simulation.gtkw simulation.vcd >/dev/null 2>&1 &

test: simulation_prove/logfile.txt simulation_cover/logfile.txt

lint: Makefile Makefile.inc
	${VERILATOR} --lint-only board.sv simulation.sv $V

Makefile.inc: rtl
	echo V = rtl/i*.sv rtl/m*.sv >Makefile.inc

simulation.sby: $V Makefile.inc simulation.sby.sh Makefile
	sh simulation.sby.sh simulation.sv $V >$@

simulation_prove/logfile.txt simulation_cover/logfile.txt: simulation.sby simulation.sv $V
	sby -f simulation.sby

simulation.elf: $V Makefile.inc simulation.cpp simulation.h simulation.uart.h

simulation.cpp: simulation.h simulation.spi.h simulation.uart.h simulation.wbc.h simulation.wb.h

board.json: $V Makefile.inc

.SUFFIXES: .sv .elf .vcd .json .asc .bit .dfu .hex .dot .pdf .py .gtkw

.sv.elf:
	${VERILATOR} -cc --Mdir $*.d --top-module $* $< $V
	${MAKE} -C $*.d -f V$*.mk
	${CXX} -I$*.d -o $@ $*.cpp ${VERILATOR_SRC} $*.d/V$*__ALL.a

.elf.vcd:
	./$<

.sv.json: $V Makefile.inc
	${YOSYS} -p "read_verilog -sv $< $V; synth_ice40 -top $* -json $@" >$*.yosys.log

.json.asc: board.pcf
	${NEXTPNR} -q -l $*.nextpnr.log --pcf board.pcf --json $< --asc $@

.asc.bit:
	${ICEPACK} $< $@

.py.gtkw:
	python $< $*

.bit.dfu:
	cp $< $@
	dfu-suffix -v 1209 -p 70b1 -a $@

.sv.dot:
	yosys -p "read_verilog -sv $<; show -format dot -prefix $*"

.dot.pdf:
	dot -Tpdf $< >$@
