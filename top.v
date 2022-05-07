`default_nettype none

module top #(
	parameter TICKS_PER_BAUD = 4
) (
	input wire clock,

	// CHARLIE7X5
	output wire [6:0] charlie7x5_o,
	output wire [6:0] charlie7x5_oe
);
	reg reset_n = 0;

	wire reset = !reset_n;

	always @(posedge clock)
		reset_n <= 1;

	// charlie7x5 //

	localparam CHARLIE7X5_STATE_READY = 2'd0;
	localparam CHARLIE7X5_STATE_WAIT_STALL = 2'd1;
	localparam CHARLIE7X5_STATE_WAIT_ACK = 2'd2;
	localparam CHARLIE7X5_STATE_DONE = 2'd3;

	reg [1:0] charlie7x5_state = 0;
	reg [3:0] charlie7x5_addr = 0;

	wire charlie7x5_stall_o;
	wire charlie7x5_ack_o;
	wire charlie7x5_dat_o;
	wire charlie7x5_unused = &{ charlie7x5_stall_o, charlie7x5_dat_o };

	wb_charlie7x5 charlie7x5 (
		.wb_clk_i(clock),
		.wb_rst_i(reset),
		.wb_cyc_i(
			charlie7x5_state >= CHARLIE7X5_STATE_WAIT_STALL
		&&	charlie7x5_state <= CHARLIE7X5_STATE_WAIT_ACK
		),
		.wb_stb_i(
			charlie7x5_state == CHARLIE7X5_STATE_WAIT_STALL
		),
		.wb_we_i(1),
		.wb_adr_i(charlie7x5_addr),
		.wb_dat_i(32'b1111111),
		.wb_dat_o(charlie7x5_dat_o),
		.wb_stall_o(charlie7x5_stall_o),
		.wb_ack_o(charlie7x5_ack_o),
		.charlie7x5_oe(charlie7x5_oe),
		.charlie7x5_o(charlie7x5_o)
	);

	always @(posedge clock) begin
		case (charlie7x5_state)
		CHARLIE7X5_STATE_WAIT_STALL:
			if (!charlie7x5_stall_o)
				charlie7x5_state <= charlie7x5_state + 1;
		CHARLIE7X5_STATE_WAIT_ACK:
			if (charlie7x5_ack_o)
				charlie7x5_state <= charlie7x5_state + 1;
		CHARLIE7X5_STATE_DONE: begin
			charlie7x5_addr <= charlie7x5_addr < 4 ? charlie7x5_addr + 1 : 0;
			charlie7x5_state <= 0;
		end
		default:
			charlie7x5_state <= charlie7x5_state + 1;
		endcase
	end

endmodule
