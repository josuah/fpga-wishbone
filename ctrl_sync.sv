`default_nettype none

/*
 * Controller for a Wishbone bus, receiving data from an synchronous serial
 * interface
 *
 * Wishbone read (single): [A]ddress [D]ata
 *  Ctrl: 00AAAAAA [ :::::::: ]* :::::::: ::::::::
 *  Peri: :::::::: [ 00000000 ]* 00000001 DDDDDDDD
 *
 * Wishbone write (single): [A]ddress [D]ata
 *  Ctrl: 01AAAAAA DDDDDDDD [ :::::::: ]* ::::::::
 *  Peri: :::::::: :::::::: [ 00000000 ]* 00000001
 *
 * Wishbone read (burst): [L]ength [D]ata
 *  Ctrl: 10LLLLLL [ :::::::: ]*L
 *  Peri: :::::::: [ DDDDDDDD ]*L
 *
 * Wishbone write (burst): [L]ength [D]ata
 *  Ctrl: 11LLLLLL [ DDDDDDDD ]*L
 *  Peri: :::::::: [ :::::::: ]*L
 */

module ctrl_sync (
  input  clk_i,
  input  rst_ni,

  // wishbone b4 controller
  output wb_we_o,
  output wb_stb_o,
  input  wb_ack_i,
  output [3:0] wb_adr_o,
  output [7:0] wb_dat_o,
  input  [7:0] wb_dat_i,

  // serial data i/o
  input  [7:0] rx_data_i,
  input  rx_req_i,
  output [7:0] tx_data_o,
  output tx_req_o
);
  typedef enum logic [2:0] {
    StIdle,
    StReadPutData,
    StReadWaitAck,
    StWriteGetData,
    StWriteWaitAck,
    StInvalid
  } state_e;

  logic wb_we_d, wb_we_q;
  logic wb_ack_d, wb_ack_q;
  logic wb_stb_d;
  logic [3:0] wb_adr_d, wb_adr_q;
  logic [7:0] wb_dat_d, wb_dat_q;
  logic [7:0] wb_dat_do;
  logic [7:0] tx_data_d;
  state_e state_d, state_q;

  assign wb_stb_o = wb_stb_d;
  assign wb_we_o = wb_we_d;
  assign wb_adr_o = wb_adr_d;
  assign wb_dat_o = wb_dat_do;
  assign tx_data_o = tx_data_d;

  // on each byte read, queue one byte to write
  assign tx_req_o = rx_req_i;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      wb_we_q <= 0;
      wb_adr_q <= 0;
      wb_ack_q <= 0;
      wb_dat_q <= 0;
      wb_dat_q <= 0;
      state_q <= 0;
    end else begin
      wb_we_q <= wb_we_d;
      wb_adr_q <= wb_adr_d;
      wb_ack_q <= wb_ack_d;
      wb_dat_q <= wb_dat_d;
      state_q <= state_d;
    end
  end

  always_comb begin
    state_d = state_q;
    wb_we_d = wb_we_q;
    wb_adr_d = wb_adr_q;
    wb_stb_d = 0;
    wb_ack_d = wb_ack_q;
    wb_dat_d = wb_dat_q;
    wb_dat_d = 0;
    wb_dat_do = 0;
    tx_data_d = 8'h00;

    if (rx_req_i) begin
      case (state_q)

        StIdle: begin
          wb_ack_d = wb_ack_i; // =0 would drop ACK coming on this clock
          wb_adr_d = rx_data_i[3:0];
          if (rx_data_i[7]) begin
            wb_we_d = 1;
            state_d = StWriteGetData;
          end else begin
            wb_we_d = 0;
            wb_stb_d = 1;
            state_d = StReadWaitAck;
          end
        end

        StWriteGetData: begin
          wb_dat_do = rx_data_i;
          wb_stb_d = 1;
          state_d = StWriteWaitAck;
        end

        StReadWaitAck: begin
          if (wb_ack_d) begin
            tx_data_d = 8'h01;
            state_d = StReadPutData;
          end
        end

        StReadPutData: begin
          tx_data_d = wb_dat_d;
          state_d = StIdle;
        end

        StWriteWaitAck: begin
          if (wb_ack_d) begin
            tx_data_d = 8'h01;
            state_d = StIdle;
          end
        end

        default: begin
          state_d = StInvalid;
        end

      endcase
    end

    // persist the acknoledge so that St{Read,Write}WaitAck could read it
    if (wb_ack_i) begin
      wb_ack_d = wb_ack_i;
      wb_dat_d = wb_dat_i;
    end
  end

endmodule
