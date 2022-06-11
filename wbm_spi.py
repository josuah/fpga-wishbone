from util.gtkw import write_gtkw
from sys import argv

prefix = 'TOP.simulation.top.wbm_spi'

traces = [
    ('io',
     [('spi_sck', 'clk'), ('spi_csn', 'io'), ('spi_sdi', 'io'),
      ('spi_sdo', 'io')]),
    ('tx',
     ['tx_handshake_ack', 'tx_handshake_req', 'tx_handshake_data[7:0]',
      'rx_data', 'tx_stb']),
    ('rx',
     ['rx_handshake_ack', 'rx_handshake_req', 'rx_handshake_data[7:0]',
      'rx_data', 'rx_stb', 'tx_ready']),
    ('state',
     [('state[3:0]', 'state')]),
    ('wb',
     [('wb_clk_i', 'clk'), 'wb_rst_i', 'wb_cyc_o', 'wb_stb_o',
      'wb_stall_i', 'wb_ack_i', 'wb_we_o', 'wb_adr_o[15:0]',
      'wb_sel_o[3:0]', 'wb_dat_i[31:0]', 'wb_dat_o[31:0]',
      'wb_data[31:0]'])
]

style = {
    'clk': {'color': 'red'},
    'io': {'color': 'yellow'},
    'state': {'color': 'violet', 'base': 'dec'}
}

write_gtkw(argv[1]+'.gtkw', argv[1]+'.vcd', traces, style,
    module=prefix, clk_period=1.0e-10)
