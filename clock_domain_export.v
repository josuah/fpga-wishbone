// Make data cross two clock domains

module clock_domain_export (
	input wire clk,

	// "other" clock domain I/O
	output reg [7:0] handshake_buffer,
	input wire handshake_other,
	output reg handshake_local,

	// "local" clock domain I/O
	input wire [7:0] data,
	input wire ack
);
	localparam STATE_1_WAIT_THEM_UP = 0;
	// Extra state to avoid metastable state on handshake_buffer:
	localparam STATE_3_WAIT_DATA_STABLE = 1;
	localparam STATE_4_WAIT_THEM_DOWN = 2;

	reg [1:0] state;

	reg data_ready_reg;
	wire data_ready = ack || data_ready_reg;

	// TODO: predict, eventually proove the number of clocks
	// required for this to work as some modules might need a
	// good lattency of data through this gate.
	always @(posedge clk) begin
		case (state)
		STATE_1_WAIT_THEM_UP: begin
			// Also wait that we are ready to transmit the next byte.
			if (handshake_other == 1 && data_ready) begin
				// We just checked on both side: we can cross
				// the street, err... I mean the clock domain.
				handshake_buffer <= data;
				data_ready_reg <= 0;
				state <= STATE_3_WAIT_DATA_STABLE;
			end
		end
		STATE_3_WAIT_DATA_STABLE: begin
			// Inform the parent module that we have the data.
			handshake_local <= 1;
			state <= STATE_4_WAIT_THEM_DOWN;
		end
		STATE_4_WAIT_THEM_DOWN: begin
			if (handshake_other == 0) begin
				handshake_local <= 0;
			end
		end
		endcase

		if (ack)
			data_ready_reg <= 1;
	end

endmodule
