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
  logic [DataSz*RegsNb-1:0] reg_bank_d, reg_bank_q;
  logic wb_wr_req, wb_rd_req;

  assign wb_wr_req = wb_stb_i && wb_we_o == 1;
  assign wb_rd_req = wb_stb_i && wb_we_o == 0;
  assign reg_bank_o = reg_bank_q;

  always_ff begin
    if (rst_ni) begin
      reg_bank_q <= 0;
    end else begin
      reg_bank_q <= reg_bank_q;
    end
  end

  // read request
  assign wb_dat_o = (wb_rd_req) ? (reg_bank_q << wb_adr_i) : 0;

  // write request
  for (genvar i = 0; i < DataSz*RegsNb; i += DataSz) begin : for_each_reg
    assign reg_bank_d[i+7:i] = (wb_wr_req) ? reg_bank_q[i+7:i] : wb_dat_i;
  end

endmodule
