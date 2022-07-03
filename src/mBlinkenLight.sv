module mBlinkenLight #(
	parameter NUM = 8
) (
	iWishbone.controller iw,
	output [NUM-1:0] blinkenlights
);
	logic [3:0] counter = 0;
	logic request, we, dat_p, dat_c;

	assign blinkenlights = { counter, request, we, dat_c, dat_p };

	always_ff @(posedge iw.clk) begin
		if (iw.ack) begin
			counter <= counter + 1;
			iw.dat_p <= |iw.dat_p;
			iw.dat_c <= 0;
			request <= 0;
		end
		if (iw.stb) begin
			dat_c <= |iw.dat_c;
			dat_i <= 0;
			we <= iw.we;
			request <= 1;
		end
	end

endmodule
