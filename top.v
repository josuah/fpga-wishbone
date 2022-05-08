`default_nettype none

module top #(
	parameter CPU_CLK_HZ = 48_000_000,
	parameter TICKS_PER_BAUD = 4
) (
	input wire clk,

	// charlie7x5
	output wire [6:0] charlie7x5_o,
	output wire [6:0] charlie7x5_oe
);
	reg rst_n = 0;

	wire rst = !rst_n;

	always @(posedge clk)
		rst_n <= 1;

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

	wbs_charlie7x5 #(
		.WB_CLK_HZ(CPU_CLK_HZ)
	) charlie7x5 (
		.wbs_clk_i(clk),
		.wbs_rst_i(rst),
		.wbs_cyc_i(
			charlie7x5_state >= CHARLIE7X5_STATE_WAIT_STALL
		&&	charlie7x5_state <= CHARLIE7X5_STATE_WAIT_ACK
		),
		.wbs_stb_i(
			charlie7x5_state == CHARLIE7X5_STATE_WAIT_STALL
		),
		.wbs_we_i(1),
		.wbs_adr_i(charlie7x5_addr),
		.wbs_dat_i(
			charlie7x5_addr == 0 ? 32'b1_0_0_0_0_0_1 :
			charlie7x5_addr == 1 ? 32'b0_1_0_0_0_0_1 :
			charlie7x5_addr == 2 ? 32'b0_0_1_1_1_1_0 :
			charlie7x5_addr == 3 ? 32'b0_1_0_0_0_0_1 :
			charlie7x5_addr == 4 ? 32'b1_0_0_0_0_0_1 :
			32'b1111111
		),
		.wbs_dat_o(charlie7x5_dat_o),
		.wbs_stall_o(charlie7x5_stall_o),
		.wbs_ack_o(charlie7x5_ack_o),
		.charlie7x5_oe(charlie7x5_oe),
		.charlie7x5_o(charlie7x5_o)
	);

	always @(posedge clk) begin
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
