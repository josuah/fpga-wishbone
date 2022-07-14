CXX = c++ -I${VERILATOR_ROOT}/include
ICEPACK = icepack
ICEPROG = iceprog
MAKE = gmake
VERILATOR = verilator -Wall -DSIMULATION -Irtl --trace --sv --trace-structs
VERILATOR_ROOT = /usr/local/share/verilator
VERILATOR_SRC = ${VERILATOR_ROOT}/include/verilated.cpp ${VERILATOR_ROOT}/include/verilated_vcd_c.cpp
NEXTPNR = nextpnr-ice40 --randomize-seed --up5k --package sg48
YOSYS = yosys
GTKWAVE = gtkwave -CM6

all: synthesis.bit simulation.vcd

include config.mk

clean:
	rm -rf verilator/ verification*/
	rm -rf *.log *.json *.asc *.bit *.hex *.elf *.vcd
	rm -rf *.dot */*.dot *.pdf */*.pdf

flash: synthesis.bit
	${ICEPROG} -d i:0x0403:0x6014:0 synthesis.bit

wave: simulation.gtkw simulation.vcd
	${GTKWAVE} -a simulation.gtkw simulation.vcd >/dev/null 2>&1 &

lint: Makefile
	${VERILATOR} --lint-only ${RTL}

${RTL}: config.mk

config.mk: rtl
	echo rtl/*.sv | fold -s -w 80 \
	| sed 's/^/	/; 1 s/^/RTL = /; s/$$/\\/; $$ s/\\$$//' >$@

test: verification_prove/logfile.txt verification_cover/logfile.txt

verification.sby: ${RTL} Makefile verification.sh
	sh verification.sh ${RTL} >$@

verification_prove/logfile.txt \
verification_cover/logfile.txt \
: verification.sby
	sby -f verification.sby

verilator/VmTopLevel.mk: ${RTL}
	${VERILATOR} -cc --Mdir verilator --top-module mTopLevel ${RTL}

verilator/VmTopLevel__ALL.a: verilator/VmTopLevel.mk
	${MAKE} -C verilator -f VmTopLevel.mk

simulation.elf: verilator/VmTopLevel__ALL.a simulation.cpp simulation.h
	${CXX} -Iverilator -o $@ simulation.cpp ${VERILATOR_SRC} verilator/VmTopLevel__ALL.a

synthesis.json: ${RTL}
	${YOSYS} -p "read_verilog -sv ${RTL}; synth_ice40 -top mSynthesis -json $@" >$*.yosys.log

.SUFFIXES: .sv .elf .vcd .json .asc .bit .dfu .hex .dot .pdf .py .gtkw

.elf.vcd:
	./$<

.json.asc: ports.pcf
	${NEXTPNR} -q -l $*.nextpnr.log --pcf ports.pcf --json $< --asc $@

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
