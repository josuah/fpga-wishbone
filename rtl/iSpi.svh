`default_nettype none
`ifndef iSpi
`define iSpi

typedef struct packed {
  logic sck;
  logic csn;
  logic dat;
} iSpi_Ctrl;

typedef struct packed {
  logic dat;
} iSpi_Peri;

`endif
