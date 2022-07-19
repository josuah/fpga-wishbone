`default_nettype none

// Controller for a Wishbone bus, receiving data from an asynchronous serial
// interface
//
// Wishbone Write
//
//  Ctrl: :1000AAAA:DDDDDDDD:///:::::::::
//  Peri: :::::::::::::::::::///:00000001
//
// Wishbone Write
//
//  Ctrl: :0000AAAA:///::::::::::
//  Peri: ::::::::::///:DDDDDDDD:
//

module ctrl_async (
  input clk_i,
  input rst_ni,

  // wishbone b4 peripheral
  input iWishbone_Peri wb_p,
  output iWishbone_Ctrl wb_c,

  // serial data i/o
  input rx_stb_o,
  input rx_data_o,
  output tx_stb_o,
  output tx_data_o
);
  typedef enum bit [2:0] {
    StIdle,
    StReadData0,
    StWriteData0,
    StReadWaitAck,
    StWriteWaitAck
  } state_e;

  state_e state_d, state_q;
  logic wb_we_q, wb_we_d;
  logic wb_adr_q, wb_adr_d;
  logic wb_stb_q, wb_stb_d;

  always_comb begin
    state_d = 0;
    wb_stb_o = 0;
    tx_stb = 0;
    tx_data = 0;

    unique case (state_d)
      StIdle: begin
        wb_we_d = rx_data[7];
        wb_adr_d = rx_data[3:0];
        if (rx_data[7]) begin
          state_d = StWriteData0;
        end else begin
          state_d = StReadData0;
          wb_stb_d = 1;
        end
      end
      StWriteData0: begin
        wb_dat_o = rx_data;
        tx_stb_o = 1'b1;
      end
      StReadWaitAck: begin
        if (wb_ack) begin
          tx_stb = 1'b1;
          tx_data = 8'b00000001;
          state_d = StIdle;
        end
      end
      StWriteWaitAck: begin
        if (wb_ack) begin
          tx_stb = 1'b1;
          tx_data = 8'b00000001;
          state_d = StIdle;
        end
      end
      default: begin
      end
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (rx_stb || wb_ack) begin
      state_q <= 0;
      wb_we_q <= 0;
      wb_adr_q <= 0;
      wb_stb_q <= 0;
    end else begin
      state_q <= state_d;
      wb_we_q <= wb_we_d;
      wb_adr_q <= wb_adr_d;
      wb_stb_q <= wb_stb_d;
    end
  end
endmodule
