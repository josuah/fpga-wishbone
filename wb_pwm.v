module wb_pwm #(
	parameter WB_ADDR_BITS = 32,
	parameter PWM_BITS = 4,
	parameter PWM_PINS = 1
) (
        // Wishbone B4
        input wire i_wb_clk,
        input wire i_wb_rst,
        input wire i_wb_stb,
        input wire i_wb_we,
        input wire [WB_ADDR_BITS-1 : 0] i_wb_addr,
        output wire [31 : 0] o_wb_data,
        output wire o_wb_stall,
        output wire o_wb_ack,

	// Output pin
	output wire [PWM_PINS-1 : 0] o_pwm_channel
);
`define SLICE(i) (PWM_BITS * (i + 1) * -1) : (PWM_BITS * i)

	genvar gv;
	integer i;

	reg [PWM_BITS-1 : 0] cnt;
	reg [PWM_PINS*PWM_BITS-1 : 0] duty_cycle;

	assign i_wb_ack = i_wb_stb & i_wb_we & (i_wb_addr < PWM_PINS);
	assign o_wb_stall = i_wb_stb & !i_wb_we;

	for (gv = 0; gv < PWM_PINS; gv++) begin
		assign o_pwm_channel[gv] = duty_cycle[`SLICE(gv)];
	end

	always @(posedge i_wb_clk) begin
		cnt <= cnt + 1;

		if (i_wb_rst)
			{ cnt, duty_cycle } <= 0;

		if (i_wb_stb & i_wb_we) begin
			for (i = 0; i < PWM_PINS; i++)
				if (i_wb_addr == i)
					duty_cycle[`SLICE(i)] <= i_wb_data;
		end
	end
endmodule
