`default_nettype none

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

module ctrl_async (
  input  clk_i,
  input  rst_ni,

  // wishbone b4 peripheral
  output wb_we_o,
  output wb_stb_o,
  input  wb_ack_i,
  output [3:0] wb_adr_o,
  output [7:0] wb_dat_o,
  input  [7:0] wb_dat_i,

  // serial data i/o
  input  [7:0] rx_data_i,
  input  rx_stb_i,
  output [7:0] tx_data_o,
  output tx_stb_o
);
  typedef enum logic [2:0] {
    StIdle,
    StReadWaitAck,
    StReadPutData,
    StWriteWaitAck,
    StWriteGetData
  } state_e;

  state_e state_q, state_d;

  logic wb_we_q, wb_we_d;
  logic wb_stb_q, wb_stb_d;
  logic [3:0] wb_adr_q, wb_adr_d;
  logic [7:0] wb_dat_q, wb_dat_d;

  assign wb_we_o = wb_we_d;
  assign wb_stb_o = wb_stb_d;
  assign wb_dat_o = wb_dat_d;
  assign wb_adr_o = wb_adr_d;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      state_q <= 0;
      wb_we_q <= 0;
      wb_adr_q <= 0;
      wb_stb_q <= 0;
      wb_dat_q <= 0;
    end else begin
      state_q <= state_d;
      wb_we_q <= wb_we_d;
      wb_adr_q <= wb_adr_d;
      wb_stb_q <= wb_stb_d;
      wb_dat_q <= wb_dat_d;
    end
  end

  logic [7:0] tx_data_w;
  logic tx_stb_w;
  assign tx_data_o = tx_data_w;
  assign tx_stb_o = tx_stb_w;

  always_comb begin
    state_d = state_q;
    wb_we_d = wb_we_q;
    wb_stb_d = wb_stb_q;
    wb_adr_d = wb_adr_q;
    wb_dat_d = wb_dat_q;
    tx_stb_w = 0;
    tx_data_w = 0;

    // wait for the async request from serial
    if (rx_stb_i) begin
      case (state_q)

        StIdle: begin
          wb_stb_d = 0;
          wb_adr_d = rx_data_i[3:0];
          if (rx_data_i[7]) begin
            wb_we_d = 1;
            state_d = StWriteGetData;
          end else begin
            wb_we_d = 0;
            state_d = StReadPutData;
          end
        end

        StWriteGetData: begin
          wb_dat_d = rx_data_i;
          wb_stb_d = 1;
          state_d = StReadWaitAck;
        end

        default: begin
        end

      endcase
    end

    // wait for the ack from the wishbone bus
    if (wb_ack_i) begin
      tx_data_w = wb_we_d ? wb_dat_i : 8'b00000001;
      tx_stb_w = 1;
      state_d = StIdle;
    end

  end

endmodule
