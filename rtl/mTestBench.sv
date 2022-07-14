module mTestBench;
	logic clk;
	logic rst;

	always #10 clk <= ~clk;

	initial begin
		rst <= 1;

		#10 rst <= 0;
	end
endmodule
