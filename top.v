`default_nettype none

`define CLOCK_RATE_HZ 48000000
`define BAUD_RATE_HZ 9600

module top #(
	parameter TICKS_PER_BAUD = 4
) (
	input wire clk,
	input wire uart_rx,
	output wire uart_tx,
	output wire led
);
	reg [2:0] state = 0;
	reg [31:0] buffer;
	reg write_mode = 0;

	wire wb_ack_o;
	wire wb_stall_o;
	wire int_uart_rx;
	wire unused = &{ wb_stall_o };

	assign led = 1;

	localparam [2:0]
		STATE_RESET = 0,
		STATE_READY = 1,
		STATE_REQUEST = 2,
		STATE_WAIT_ACK = 3,
		STATE_END = 4;

	wb_uart #(
		.TICKS_PER_BAUD(`CLOCK_RATE_HZ / `BAUD_RATE_HZ)
	) uart (
		.wb_clk_i(clk),
		.wb_rst_i(state == STATE_RESET),
		.wb_stb_i(state == STATE_REQUEST),
		.wb_cyc_i(state >= STATE_REQUEST && state <= STATE_WAIT_ACK),
		.wb_we_i(write_mode),
		.wb_adr_i(0),
		.wb_dat_i(buffer),
		.wb_dat_o(buffer),
		.wb_stall_o(wb_stall_o),
		.wb_ack_o(wb_ack_o),
		.int_uart_rx(int_uart_rx),
		.uart_tx(uart_tx),
		.uart_rx(uart_rx)
	);

	// main state machine: issue requests over wishbone
	always @(posedge clk) begin
		case (state)
		STATE_READY: begin
			// either we are writing and do not need to wait,
			// either we are reading and will wait the interrupt,
			if (write_mode || int_uart_rx)
				state <= state + 1;
		end
		STATE_REQUEST: begin
			if (!wb_stall_o)
				state <= state + 1;
		end
		STATE_WAIT_ACK: begin
			if (wb_ack_o)
				state <= state + 1;
		end
		STATE_END: begin
			// swap between reading and writing mode
			write_mode <= !write_mode;
			state <= STATE_READY;
		end
		default: begin
			state <= state + 1;
		end
		endcase
	end
endmodule
