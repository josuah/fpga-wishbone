`default_nettype none

// This part exports a buffer of data to the other clock domain.
// Rising `stb` for one clock queues `data` for transfer. To use
// only when ready.

module mClockDomainExporter#(
	parameter pBits = 8
)(
	input	logic clk,
	input	logic rst,
	input	iClockDomain_Imp cd_i,
	output	iClockDomain_Exp cd_e,
	input	logic stb,
	input	logic[pBits-1:0] data,
	output	logic ready
);
	logic[1:0] ack_ff;

	assign ready = (ack_ff[0] == cd_e.req);

	always_ff @(posedge clk) begin
		// 2FF buffer to prevent metastable state propagation
		ack_ff <= {cd_i.ack, ack_ff[1]};

		if (stb && ready) begin
			cd_e.data <= data;
			cd_e.req <= !cd_e.req;
		end

		if (rst) begin
			{ack_ff, cd_e.data, cd_e.req} <= 0;
		end
	end
endmodule
