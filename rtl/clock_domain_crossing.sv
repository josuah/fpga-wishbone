`default_nettype none
//
// Simple handshake protocol for crossing clock domain.
//
// * The source module sending the data to another clock domain writes to
//   `ack` (and reads `req`).
// * The destination module receiving data from another clock domain writes to
//   `req` (and reads `ack`).
//
//          :   :   :   :   :   :   :   :   :   :   :   :
//        __:_______________:_______________:______________
//   data __X_______________X_______________X______________
//          :    _______________:   :   :   :    __________
//    req ______/   :   :   :   \_______________/   :   :
//          :   :   :   :_______________:   :   :   :   :__
//    ack ______________/   :   :   :   \_______________/
//          :   :   :   :   :   :   :   :   :   :   :   :
//         (1) (2) (3) (4) (1) (2) (3) (4) (1) (2) (3) (4)
//
// * When the source has data to transfer,
//   it first asserts `data` to the data to transfer (1) then invert `req` (2).
// * Once the destination notices it,
//   it copies `data` to a local register (3) then sets `ack` to
//   the same value as `req` (4).
//
// References:
// http://web.cse.msu.edu/~cse820/readings/sutherlandMicropipelinesTuring.pdf
// http://www.sunburst-design.com/papers/CummingsSNUG2008Boston_CDC.pdf
// https://zipcpu.com/blog/2018/07/06/afifo.html
//
module clock_domain_crossing #(
  parameter Bits = 8
) (
  input clk_src_i,
  input clk_dst_i,

  // export from source
  input src_valid_i,
  output src_ready_o,
  input [Bits-1:0] src_data_i,

  // import at destination
  output dst_valid_o,
  output [Bits-1:0] dst_data_o
);
  // signals which will cross the clock domain
  logic src_req_d, src_req_q, metastable_req_q, dst_req_q2;
  logic dst_ack_d, dst_ack_q, metastable_ack_q, src_ack_q2;
  logic [Bits-1:0] src_data_d, src_data_q;

  // request from source to destination clock domain
  always_ff @(posedge clk_dst_i) begin
    dst_ack_q <= dst_ack_d;
    metastable_req_q <= src_req_d;
    dst_req_q2 <= metastable_req_q;
  end

  // acknoledgement from destination to source clock domain
  always_ff @(posedge clk_src_i) begin
    src_req_q <= src_req_d;
    metastable_ack_q <= dst_ack_q;
    src_ack_q2 <= metastable_ack_q;
    src_data_q <= src_data_d;
  end

  always_comb begin
    src_data_d = src_data_q;
    src_req_d = src_req_q;

    // on incoming request latch the data and flip the `req` signal
    if (src_ready_o && src_valid_i) begin
      src_data_d = src_data_i;
      src_req_d = ~src_req_q;
    end
  end

  // ready to receive more data when the acknoledgement is done
  assign src_ready_o = (src_ack_q2 == src_req_q);

  // pass data through, guarded by the control signals
  assign dst_data_o = src_data_q;

  // data goes through when we we receive a request not yet acknoledged
  assign dst_valid_o = (dst_req_q2 != dst_ack_q);

  // the `ack` signal follows the `req` signal
  assign dst_ack_d = dst_req_q2;

endmodule
