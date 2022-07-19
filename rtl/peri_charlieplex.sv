`default_nettype none

module mCharlieplex #(
  parameter ClkHz = 0
) (
  input logic clk_i,
  input logic rst_ni,
  input iWishbone_Peri wb_p,
  input iWishbone_Ctrl wb_c,
  output logic [6:0] charlieplex_o,
  output logic [6:0] charlieplex_oe
);
  localparam MemSize = 1 << $clog2(5);
  localparam DelayHz = 100000;

  logic [2:0] row, col;
  // memory for the screen pixels
  logic [MemSize-1:0] mem[4:0];
  logic [MemSize-1:0] mem_wr_data;
  logic [$clog2(MemSize)-1:0] mem_wr_addr;
  // clock divider for reducing the refresh rate
  logic [$clog2(ClkHz / DelayHz)-1:0] cnt;
  logic dot;
  logic [2:0] col_pin, row_pin;

  // is the current pixel on or off?
  assign dot = mem[row][col];

  // row and col use the same pins, with priority to the cols,
  // and the row shifted by one when they overlap
  assign col_pin = col;
  assign row_pin = (row + 1 < col) ? row + 1 : row + 2;

  assign wb_dat = 0;
  assign wb_ack = wb_stb;

  assign charlieplex_o = dot ? (1 << row_pin) : 0;
  assign charlieplex_oe = dot ? (1 << row_pin) | (1 << col_pin) : 0;

  always_ff @(posedge clk_i) begin
    mem[mem_wr_addr] <= mem_wr_data;
  end

  always_ff @(posedge clk_i) begin
    // scale the clock down
    cnt <= cnt + 1;
    if (cnt == 0) begin
      // scan rows one byu one to set a single
      // pixel of the row high or low
      row <= row + 1;

      // why do I have to set it to 5 and not 4?
      // it behaves differently in hardware and
      // software
      if (row == 4) begin
        row <= 0;

        // once the row is complete, switch
        // to the next column
        col <= (col == 6) ? 0 : col + 1;
      end
    end

    if (wb_stb && wb_we) begin
      mem_wr_data <= wb_dat[7:0];
      mem_wr_addr <= wb_adr[$clog2(MemSize)-1:0];
    end

    if (!rst_ni) begin
      {row, col, cnt, mem_wr_data, mem_wr_addr} <= 0;
    end
  end

endmodule