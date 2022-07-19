CXX = c++ -I${VERILATOR_ROOT}/include
ICEPACK = icepack
ICEPROG = iceprog
MAKE = gmake
VERILATOR = verilator -Wall -DSIMULATION -Irtl --trace --sv --trace-structs --Mdir verilator
VERILATOR_ROOT = /usr/local/share/verilator
VERILATOR_SRC = ${VERILATOR_ROOT}/include/verilated.cpp ${VERILATOR_ROOT}/include/verilated_vcd_c.cpp
NEXTPNR = nextpnr-ice40 --randomize-seed --up5k --package sg48
YOSYS = yosys
GTKWAVE = gtkwave -CM6
COCOTB = ${MAKE} -f "$$(cocotb-config --makefiles)/Makefile.sim" \
  MAKE="${MAKE}" SIM="verilator" TOPLEVEL_LANG="verilog" VERILOG_SOURCES="${RTL}" \
  EXTRA_ARGS="--trace --trace-structs" 

all: synthesis.bit verilator/VmTopLevel.vcd

include config.mk

clean:
	rm -rf */*.dot */*.pdf *.log *.json *.asc *.bit *.hex

flash: synthesis.bit
	${ICEPROG} -d i:0x0403:0x6014:0 synthesis.bit

wave: VmTopLevel.gtkw verilator/VmTopLevel.vcd
	${GTKWAVE} -a VmTopLevel.gtkw verilator/VmTopLevel.vcd

cocotb: ${RTL} ${TB:.py=.xml}

${RTL}: config.mk

config.mk: rtl tb
	echo RTL = rtl/*.sv >$@ 
	echo TB = tb/*.py >>$@

verilator/VmTopLevel.mk: ${RTL}
	${VERILATOR} -cc --top-module mTopLevel ${RTL}

verilator/VmUartRx.mk: ${RTL}
	${VERILATOR} -cc --top-module mUartRx ${RTL}

verilator/VmWishboneCtrlUart.mk: ${RTL}
	${VERILATOR} -cc --top-module mWishboneCtrlUart ${RTL}

synthesis.json: ${RTL}
	${YOSYS} -p "read_verilog -sv ${RTL}; synth_ice40 -top mSynthesis -json $@" >$*.yosys.log

.SUFFIXES: .sv .elf .vcd .json .asc .bit .dfu .hex .dot .pdf .1.pdf .2.pdf .py .gtkw .mk __ALL.a .xml

.mk__ALL.a:
	${MAKE} -C ${<D} -f ${<F}

__ALL.a.elf:
	${CXX} -DVM=${*F} -I./verilator/ -I./src/ -o $@ src/${*F}.cpp ${VERILATOR_SRC} $<

.elf.vcd:
	./$< >$@

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
	${YOSYS} -p "read_verilog -sv $<; show -format dot -prefix $*"

.dot.pdf:
	dot -Tpdf $< >$@

.py.xml: ${RTL}
	${COCOTB} TOPLEVEL="${*F}" MODULE="tb.${*F}" SIM_BUILD="$*" \
	  COCOTB_RESULTS_FILE="$*.xml"
	mv dump.vcd $*

