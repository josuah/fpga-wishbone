`default_nettype none
`include "rtl/iWishbone.svh"

// Wishbone read:
//
//  W000SSSS AAAAAAAA :::::::: :::::::: :::::::: :::::::: :::::::: ::::::::
//  │   ├──┘ ├──────┘
//  │:::│::: │::::::: 00000000 11111111 DDDDDDDD DDDDDDDD DDDDDDDD DDDDDDDD
//  │   │    │        ├──────┘ ├──────┘ ├─────────────────────────────────┘
//  WE  SEL  ADR      STALL    ACK      DAT
//
// Wishbone write:
//
//  W000SSSS AAAAAAAA DDDDDDDD DDDDDDDD DDDDDDDD DDDDDDDD :::::::: ::::::::
//  │   ├──┘ ├──────┘ ├─────────────────────────────────┘
//  │:::│::: │::::::: │::::::: :::::::: :::::::: :::::::: 00000000 11111111
//  │   │    │        │                                   ├──────┘ ├──────┘
//  WE  SEL  ADR      DAT                                 STALL    ACK
//

typedef enum {
  eWishboneCtrlSyncState_Idle,
  eWishboneCtrlSyncState_GetAddress,
  eWishboneCtrlSyncState_WaitAck,
  eWishboneCtrlSyncState_ReadData,
  eWishboneCtrlSyncState_WriteData,
  eWishboneCtrlSyncState_WriteStallAck
} eWishboneCtrlSyncState;

module mWishboneCtrlSync (
  input logic clk,
  input logic rst,
  output iWishbone_Ctrl wb_c,
  input iWishbone_Peri wb_p,
  input logic [7:0] rx_data,
  input logic rx_stb,
  output logic [7:0] tx_data,
  output logic tx_stb
);
  logic [7:0] tx_data_buf;
  eWishboneCtrlSyncState state;

  always_ff @(posedge clk) begin
    if (wb_p.ack) begin
      tx_data_buf <= wb_p.dat; // only used if wb_c.we
      wb_c.stb <= 0;
    end

    // on each byte read, queue one byte to write
    tx_stb <= rx_stb;

    if (rx_stb) begin
      case (state)
      eWishboneCtrlSyncState_Idle: begin  // Rx:W000SSSS
        wb_c.we <= rx_data[7];
        tx_data <= 8'h00;  // Tx:00000000
        if (|rx_data) // skip 0x00
          state <= eWishboneCtrlSyncState_GetAddress;
      end
      eWishboneCtrlSyncState_GetAddress: begin  // Rx:AAAAAAAA
        wb_c.adr <= {rx_data[3:0]};
        if (wb_c.we) begin
          // wait to have data to write
          state <= eWishboneCtrlSyncState_WriteData;
        end else begin
          // wishbone read with that address
          wb_c.stb <= 1;
          state <= eWishboneCtrlSyncState_WaitAck;
        end
      end
      eWishboneCtrlSyncState_WaitAck: begin  // Tx:00000000
        if (!wb_c.stb) begin  // Tx:11111111
          tx_data <= 8'hFF;
          state <= eWishboneCtrlSyncState_ReadData;
        end
      end
      eWishboneCtrlSyncState_ReadData: begin  // Tx:DDDDDDDD
        tx_data <= tx_data_buf;
        state <= eWishboneCtrlSyncState_Idle;
      end
      eWishboneCtrlSyncState_WriteData: begin  // Rx:DDDDDDDD
        wb_c.dat <= rx_data;
        state <= eWishboneCtrlSyncState_WriteStallAck;
        wb_c.stb <= 1;
      end
      eWishboneCtrlSyncState_WriteStallAck: begin  // Tx:00000000
        if (!wb_c.stb) begin  // Tx:11111111
          tx_data <= 8'hFF;
          state <= eWishboneCtrlSyncState_Idle;
        end
      end
      endcase
    end

    if (rst) begin
      {tx_data, tx_stb, tx_data_buf, state} <= 0;
    end
  end
endmodule
