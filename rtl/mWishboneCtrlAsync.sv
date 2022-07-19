`default_nettype none
`include "rtl/iWishbone.svh"

// Controller for a Wishbone bus, receiving data from an asynchronous serial interface

// Wishbone read:
//
//  :0000AAAA:///::::::::::
//   │   ├──┘ 
//  :│:::│::::///:DDDDDDDD:
//   │   │        ├──────┘
//   We  Adr      Dat
//
// Wishbone write:
//
//  :1000AAAA:DDDDDDDD:///::::::::::
//   │   ├──┘ ├──────┘ 
//  :│:::│::::│::::::::///:00000001:
//   │   │    │            ├──────┘
//   We  Adr  Dat          Ack
//
//
// Wr:  Ctrl: -1000AAAA-DDDDDDDD-///---------
//  Peri: -------------------///-00000001
//
// Rd:  Ctrl: -0000AAAA-///----------
//  Peri: ----------///-DDDDDDDD-

typedef enum {
  eWishboneCtrlAsync_Idle,
  eWishboneCtrlAsync_RdData0,
  eWishboneCtrlAsync_WrData0,
  eWishboneCtrlAsync_RdWaitAck,
  eWishboneCtrlAsync_WrWaitAck
} eWishboneCtrlAsyncState;

module mWishboneCtrlAsync(
  input logic clk,
  input logic rst,
  input iWishbone_Peri wb_p,
  output  iWishbone_Ctrl wb_c,
  input logic rx_stb,
  input logic rx_data,
  output  logic tx_stb,
  output  logic tx_data
  
);
  eWishboneCtrlAsyncState state;

  always_ff @(posedge clk) begin
    wb_c.stb <= 0;
    if (rx_stb || wb_p.ack) begin
      case (state)
      eWishboneCtrlAsync_Idle: begin
        wb_c.we <= rx_data[7];
        wb_c.adr <= rx_data[3:0];
        if (rx_data[7]) begin
          state <= eWishboneCtrlAsync_WrData0;
        end else begin
          state <= eWishboneCtrlAsync_RdData0;
          wb_c.stb <= 1;
        end
          
      end
      eWishboneCtrlAsync_WrData0: begin
        wb_c.dat <= rx_data;
        tx_stb <= 1'b1;
      end
      eWishboneCtrlAsync_RdWaitAck: begin
        if (wb_p.ack) begin
          tx_stb <= 1'b1;
          tx_data <= 8'b00000001;
          state <= eWishboneCtrlAsync_Idle;
        end
      end
      eWishboneCtrlAsync_WrWaitAck: begin
        if (wb_p.ack) begin
          tx_stb <= 1'b1;
          tx_data <= 8'b00000001;
          state <= eWishboneCtrlAsync_Idle;
        end
      end
      endcase
    end
  end
endmodule
