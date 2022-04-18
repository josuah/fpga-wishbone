module wb_pwm #(
	parameter WB_ADDR_BITS = 32,
	parameter PWM_BITS = 4,
	parameter PWM_CHANS = 1
) (
        // Wishbone B4
        input wire i_wb_clk,
        input wire i_wb_rst,
        input wire i_wb_stb,
        input wire i_wb_we,
        input wire [WB_ADDR_BITS-1:0] i_wb_addr,
        input wire [31:0] i_wb_data,
        output wire o_wb_stall,
        output wire o_wb_ack,

	// Output pin
	output wire [PWM_CHANS-1:0] o_pwm_chan
);

`define DUTY_CYCLE(i) duty_cycle[PWM_BITS*(i+1)-1:PWM_BITS*i]

	genvar g;
	integer i;

	reg [PWM_BITS-1:0] cnt;
	reg [PWM_BITS*PWM_CHANS-1:0] duty_cycle;

	assign i_wb_ack = i_wb_stb & i_wb_we & (i_wb_addr < PWM_CHANS);
	assign o_wb_stall = i_wb_stb & !i_wb_we;
	for (g = 0; g < PWM_CHANS; g++)
		assign o_pwm_chan[g] = (cnt > `DUTY_CYCLE(g));

	always @(posedge i_wb_clk) begin
		cnt <= cnt + 1;

		if (i_wb_rst)
			{ cnt, duty_cycle } <= 0;

		if (i_wb_stb & i_wb_we) begin
			for (i = 0; i < PWM_CHANS; i++)
				if (i_wb_addr == i)
					`DUTY_CYCLE(i) <= i_wb_data;
		end
	end
endmodule

`ifdef FORMAL

	always @(posedge i_wb_clk) begin
		// TODO
	end

`endif
