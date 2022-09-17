`default_nettype none

module top #(
  parameter int AddrSz = 4,
  parameter int DataSz = 8
) (
  input  clk_i,
  input  rst_ni,

  // uart
  input  uart_rx_ni,
  output uart_tx_no,

  // led gpio
  output led_r_o,
  output led_g_o,
  output led_b_o,
  output [7:0] led_debug_o,

  // charlieplexed gpio
  output [6:0] charlieplex_o,
  output [6:0] charlieplex_out_en_o
);
  logic ctrl_wb_we, ctrl_wb_stb, ctrl_wb_ack;
  logic [AddrSz-1:0] ctrl_wb_adr;
  logic [DataSz-1:0] ctrl_wb_dat_i, ctrl_wb_dat_o;
  ctrl_uart ctrl (
    .clk_i, .rst_ni,
    .wb_we_o(ctrl_wb_we),
    .wb_adr_o(ctrl_wb_adr),
    .wb_dat_o(ctrl_wb_dat_o),
    .wb_stb_o(ctrl_wb_stb),
    .wb_dat_i(ctrl_wb_dat_i),
    .wb_ack_i(ctrl_wb_ack),
    .uart_rx_ni, .uart_tx_no
  );

  logic peri0_wb_we, peri0_wb_stb, peri0_wb_ack;
  logic [AddrSz-1:0] peri0_wb_adr;
  logic [DataSz-1:0] peri0_wb_dat_i, peri0_wb_dat_o;
  peri_rgb_led peri0 (
    .clk_i, .rst_ni,
    .wb_we_i(peri0_wb_we),
    .wb_adr_i(peri0_wb_adr),
    .wb_dat_i(peri0_wb_dat_i),
    .wb_stb_i(peri0_wb_stb),
    .wb_dat_o(peri0_wb_dat_o),
    .wb_ack_o(peri0_wb_ack),
    .led_r_o, .led_g_o, .led_b_o
  );
  assign peri0_wb_dat_i = ctrl_wb_dat_o;
  assign peri0_wb_adr = ctrl_wb_adr[3:0];
  assign peri0_wb_we = ctrl_wb_we;

  logic peri1_wb_we, peri1_wb_stb, peri1_wb_ack;
  logic [AddrSz-1:0] peri1_wb_adr;
  logic [DataSz-1:0] peri1_wb_dat_i, peri1_wb_dat_o;
  peri_debug peri1 (
    .clk_i, .rst_ni,
    .wb_we_i(peri1_wb_we),
    .wb_stb_i(peri1_wb_stb),
    .wb_ack_o(peri1_wb_ack),
    .wb_adr_i(peri1_wb_adr),
    .wb_dat_i(peri1_wb_dat_i),
    .wb_dat_o(peri1_wb_dat_o),
    .debug_o(led_debug_o)
  );
  assign peri1_wb_dat_i = ctrl_wb_dat_o;
  assign peri1_wb_adr = ctrl_wb_adr[3:0];
  assign peri1_wb_we = ctrl_wb_we;

  logic peri2_wb_we, peri2_wb_stb, peri2_wb_ack;
  logic [AddrSz-1:0] peri2_wb_adr;
  logic [DataSz-1:0] peri2_wb_dat_i, peri2_wb_dat_o;
  peri_charlieplex peri2 (
    .clk_i, .rst_ni,
    .wb_we_i(peri2_wb_we),
    .wb_stb_i(peri2_wb_stb),
    .wb_ack_o(peri2_wb_ack),
    .wb_adr_i(peri2_wb_adr),
    .wb_dat_i(peri2_wb_dat_i),
    .wb_dat_o(peri2_wb_dat_o),
    .charlieplex_o, .charlieplex_out_en_o
  );
  assign peri2_wb_dat_i = ctrl_wb_dat_o;
  assign peri2_wb_adr = ctrl_wb_adr[3:0];
  assign peri2_wb_we = ctrl_wb_we;

  always_comb begin
    ctrl_wb_dat_i = 8'b00000000;
    ctrl_wb_ack = 1'b0;
    peri0_wb_stb = 0;
    peri1_wb_stb = 0;
    peri2_wb_stb = 0;

    case (ctrl_wb_adr)
      AddrSz'(0): begin
        ctrl_wb_dat_i = peri0_wb_dat_o;
        ctrl_wb_ack = peri0_wb_ack;
        peri0_wb_stb = ctrl_wb_stb;
      end
      AddrSz'(1): begin
        ctrl_wb_dat_i = peri1_wb_dat_o;
        ctrl_wb_ack = peri1_wb_ack;
        peri1_wb_stb = ctrl_wb_stb;
      end
      AddrSz'(2): begin
        ctrl_wb_dat_i = peri2_wb_dat_o;
        ctrl_wb_ack = peri2_wb_ack;
        peri2_wb_stb = ctrl_wb_stb;
      end
      default:;
    endcase
  end

endmodule
