`default_nettype none
//
// Controller for a Wishbone bus, receiving data from an asynchronous serial
// interface
//
// Wishbone read
//
//  Ctrl: :0000AAAA:///::::::::::
//  Peri: ::::::::::///:DDDDDDDD:
//
// Wishbone Write
//
//  Ctrl: :1000AAAA:DDDDDDDD:///:::::::::
//  Peri: :::::::::::::::::::///:00000001
//
module ctrl_async (
  input clk_i,
  input rst_ni,

  // wishbone b4 peripheral
  output wb_we_o,
  output wb_adr_o,
  output wb_dat_o,
  output wb_stb_o,
  input wb_dat_i,
  input wb_ack_i,

  // serial data i/o
  input rx_req_i,
  input rx_data_i,
  output tx_req_o,
  output tx_data_o
);
  typedef enum logic [1:0] {
    StIdle,
    StReadWaitAck,
    StReadGetData,
    StWaitAck,
  } state_e;

  state_e state_q, state_d;

  logic wb_we_q, wb_we_d;
  logic wb_adr_q, wb_adr_d;
  logic wb_dat_q, wb_dat_d;
  logic wb_stb_q, wb_stb_d;

  assign wb_we_o = wb_we_d;
  assign wb_adr_o = wb_adr_d;
  assign wb_dat_o = wb_dat_d;
  assign wb_stb_o = wb_stb_d;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      state_q <= 0;
      wb_we_q <= 0;
      wb_adr_q <= 0;
      wb_stb_q <= 0;
      wb_dat_q <= 0;
      wb_ack_i <= 0;
    end else begin
      state_q <= state_d;
      wb_we_q <= wb_we_d;
      wb_adr_q <= wb_adr_d;
      wb_stb_q <= wb_stb_d;
      wb_dat_q <= wb_dat_d;
    end
  end

  always_comb begin
    state_d = state_q;
    wb_we_d = wb_we_q;
    wb_stb_d = wb_stb_d;
    wb_dat_d = wb_dat_q;
    tx_req_o = 0;

    // wait for the async request from serial
    if (rx_req_i) begin
      unique case (state_q)

        StIdle: begin
          wb_stb_d = 0;
          wb_adr_d = rx_data_i[3:0];
          if (rx_data_i[7]) begin
            wb_we_d = 1;
            state_d = StWriteGetData;
          end else begin
            wb_we_d = 0;
            state_d = StReadGetData;
          end
        end

        StWriteGetData: begin
          wb_dat_d = rx_data_i;
          wb_stb_d = 1;
          state_d = StReadWaitAck;
        end

        default: ;

      endcase
    end

    // wait for the ack from the wishbone bus
    if (wb_ack_i) begin
      tx_data_o = wb_we_d ? wb_dat_i : 8'b00000001;
      tx_req_o = 1;
      state_d = StIdle;
    end

  end

endmodule
