`default_nettype none

// Controller for a Wishbone bus, receiving data from an asynchronous serial
// interface
//
// Wishbone read
//
//  Ctrl: :0000AAAA:///::::::::::
//  Peri: ::::::::::///:DDDDDDDD:
//

// General purpose register bank.
// It takes the burden of handling read/write wishbone request to
// configure registers out of the view, and lets one 

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
    assign reg_bank_d[DataSz*(i+1)-1:DataSz*i] = (wb_wr_req && wb_adr_i == i) ? wb_dat_i : reg_bank_q[DataSz*(i+1)-1:DataSz*i];
  end

endmodule
