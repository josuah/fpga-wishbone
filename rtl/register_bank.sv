`default_nettype none

// General purpose register bank.
// This module implement wishbone read from, and write to registers that
// can later be read by the peripherals.

module register_bank #(
  AddrSz = 4,
  DataSz = 8,
  RegsNb = 3
) (
  input  clk_i,
  input  rst_ni,

  // wishbone b4
  input  wb_we_i,
  input  wb_stb_i,
  output wb_ack_o,
  input  [AddrSz-1:0] wb_adr_i,
  input  [DataSz-1:0] wb_dat_i,
  output [DataSz-1:0] wb_dat_o,

  // registers access
  output [DataSz*RegsNb-1:0] reg_bank_o
);
  logic [DataSz*RegsNb-1:0] reg_bank_d, reg_bank_q, reg_bank_shift;
  logic wb_wr_req, wb_rd_req;

  assign wb_ack_o = wb_stb_i;
  assign reg_bank_o = reg_bank_q;
  assign wb_wr_req = wb_stb_i && wb_we_i == 1;
  assign wb_rd_req = wb_stb_i && wb_we_i == 0;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      reg_bank_q <= 0;
    end else begin
      reg_bank_q <= reg_bank_d;
    end
  end

  // read request
  assign reg_bank_shift = reg_bank_q >> {wb_adr_i, 3'b000};
  assign wb_dat_o = wb_rd_req ? reg_bank_shift[7:0] : 0;

  // write request
  for (genvar i = 0; i < RegsNb; i++) begin : for_each_reg
    `define i0 DataSz * i
    `define i1 DataSz * (i + 1) - 1
    `define en (wb_wr_req && wb_adr_i == i)
    assign reg_bank_d[`i0:`i1] = `en ? wb_dat_i : reg_bank_q[`i1:`i0];
  end

endmodule
