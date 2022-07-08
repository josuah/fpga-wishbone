from gtkw import write_gtkw
from sys import argv

def group(pfx):
    return (pfx, [(pfx + '.*')])

traces = [
    group('mspi.spi'),
    group('mspi.mstate'),
    group('mspi.mexp'),
    group('mspi.tx_cdc'),
    group('mspi.mtx.mimp.cdc'),
]

style = {
    'clk': {'color': 'red'},
    'io': {'color': 'yellow'},
    'state': {'color': 'violet', 'base': 'dec'}
}

write_gtkw(argv[1]+'.gtkw', argv[1]+'.vcd', traces, style,
    module='TOP.mTopLevel', clk_period=1.0e-10)
