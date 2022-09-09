ICEPACK = icepack
ICEPROG = iceprog
MAKE = gmake
VERILATOR = verilator -Wall -DSIMULATION --sv
NEXTPNR = nextpnr-ice40 --randomize-seed --up5k --package sg48
YOSYS = yosys
COCOTB = ${MAKE} -f "$$(cocotb-config --makefiles)/Makefile.sim" MAKE="${MAKE}" \
  SIM="verilator" EXTRA_ARGS="--trace" TOPLEVEL_LANG="verilog" \
  VERILOG_SOURCES="${RTL}"

all: ice40.bit

include config.mk

clean:
	rm -rf tb/*.d */*.dot */*.pdf */*.xml *.log *.json *.asc *.bit *.hex

lint:
	${VERILATOR} --lint-only --sv --top-module top ${RTL}

flash: ice40.bit
	${ICEPROG} -d i:0x0403:0x6014:0 ice40.bit

test: ${RTL} ${TB:.py=.xml}

%{TB:.py=.xml}: ${RTL}

${RTL}: config.mk

config.mk: rtl tb
	echo RTL = rtl/*.sv >$@ 
	echo TB = tb/*.py >>$@

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
	${COCOTB} TOPLEVEL="${*F}" MODULE="tb.${*F}" SIM_BUILD="$*.d" \
	  COCOTB_RESULTS_FILE="$*.xml"
	mv dump.vcd $*.d/dump.vcd
