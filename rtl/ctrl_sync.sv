`default_nettype none

// Wishbone read:
//
//  Ctrl: W000SSSS AAAAAAAA :::::::: :::::::: :::::::: :::::::: :::::::: ::::::::
//  Peri: :::::::: :::::::: 00000000 11111111 DDDDDDDD DDDDDDDD DDDDDDDD DDDDDDDD
//
// Wishbone write:
//
//  Ctrl: W000SSSS AAAAAAAA DDDDDDDD DDDDDDDD DDDDDDDD DDDDDDDD :::::::: ::::::::
//  Peri: :::::::: :::::::: :::::::: :::::::: :::::::: :::::::: 00000000 11111111
//

typedef enum {
  StIdle,
  StGetAddress,
  StWaitAck,
  StReadData,
  StWriteData,
  StWriteStallAck
} state_e;

module ctrl_sync (
  input logic clk_i,
  input logic rst_ni,

  output iWishbone_Ctrl wb_c,
  input iWishbone_Peri wb_p,
  input logic [7:0] rx_data,
  input logic rx_stb,
  output logic [7:0] tx_data,
  output logic tx_stb
);
  logic [7:0] tx_data_buf;
  state_e state;

  always_ff @(posedge clk_i) begin
    if (wb_ack) begin
      tx_data_buf <= wb_dat; // only used if wb_we
      wb_stb <= 0;
    end

    // on each byte read, queue one byte to write
    tx_stb <= rx_stb;

    if (rx_stb) begin
      case (state)
      StIdle: begin  // Rx:W000SSSS
        wb_we <= rx_data[7];
        tx_data <= 8'h00;  // Tx:00000000
        if (|rx_data) // skip 0x00
          state <= StGetAddress;
      end
      StGetAddress: begin  // Rx:AAAAAAAA
        wb_adr <= {rx_data[3:0]};
        if (wb_we) begin
          // wait to have data to write
          state <= StWriteData;
        end else begin
          // wishbone read with that address
          wb_stb <= 1;
          state <= StWaitAck;
        end
      end
      StWaitAck: begin  // Tx:00000000
        if (!wb_stb) begin  // Tx:11111111
          tx_data <= 8'hFF;
          state <= StReadData;
        end
      end
      StReadData: begin  // Tx:DDDDDDDD
        tx_data <= tx_data_buf;
        state <= StIdle;
      end
      StWriteData: begin  // Rx:DDDDDDDD
        wb_dat <= rx_data;
        state <= StWriteStallAck;
        wb_stb <= 1;
      end
      StWriteStallAck: begin  // Tx:00000000
        if (!wb_stb) begin  // Tx:11111111
          tx_data <= 8'hFF;
          state <= StIdle;
        end
      end
      endcase
    end

    if (!rst_ni) begin
      {tx_data, tx_stb, tx_data_buf, state} <= 0;
    end
  end
endmodule
