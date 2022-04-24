`default_nettype none

module top #(
	parameter TICKS_PER_BAUD = 4
) (
	input wire clock,

	// UART control I/O
	input wire uart_rx,
	output wire uart_tx,

	// PWM output
	output pwm_motor_o
);
	reg not_reset = 0;
	wire reset = !not_reset;
	wire unused = &{ pwm_dat_o };

	always @(posedge clock)
		not_reset <= 1;


	// UART module

	localparam [2:0]
		UART_STATE_IDLE = 0,
		UART_STATE_REQUEST = 1,
		UART_STATE_WAIT_ACK = 2,
		UART_STATE_END = 3;

	reg [2:0] uart_state = 0;
	reg [31:0] uart_buffer;
	reg uart_write_mode = 0;

	wire uart_ack_o;
	wire uart_stall_o;
	wire int_uart_rx;
	wire [31:0] uart_dat_o;

	// main state machine for UART: receive requestst from wishbone,
	// issue responses over wishbone
	always @(posedge clock) begin
		case (uart_state)
		UART_STATE_IDLE: begin
			// either we are writing and do not need to wait,
			// either we are reading and will wait the interrupt,
			if (uart_write_mode || int_uart_rx)
				uart_state <= uart_state + 1;
		end
		UART_STATE_REQUEST: begin
			if (!uart_stall_o)
				uart_state <= uart_state + 1;
		end
		UART_STATE_WAIT_ACK: begin
			if (uart_ack_o) begin
				uart_state <= uart_state + 1;
				uart_buffer <= uart_dat_o;
			end
		end
		UART_STATE_END: begin
			// swap between reading and writing mode
			uart_write_mode <= !uart_write_mode;
			uart_state <= UART_STATE_IDLE;
		end
		default: begin
			uart_state <= uart_state + 1;
		end
		endcase
	end

	wb_uart #(
		.TICKS_PER_BAUD(TICKS_PER_BAUD)
	) uart (
		.wb_clk_i(clock),
		.wb_rst_i(reset),
		.wb_stb_i(uart_state == UART_STATE_REQUEST),
		.wb_cyc_i(uart_state >= UART_STATE_REQUEST
			&& uart_state <= UART_STATE_WAIT_ACK),
		.wb_we_i(uart_write_mode),
		.wb_adr_i(0),
		.wb_dat_i(uart_buffer),
		.wb_dat_o(uart_dat_o),
		.wb_stall_o(uart_stall_o),
		.wb_ack_o(uart_ack_o),
		.int_uart_rx(int_uart_rx),
		.uart_tx(uart_tx),
		.uart_rx(uart_rx)
	);


	// PWM module

	localparam [2:0]
		PWM_STATE_IDLE = 0,
		PWM_STATE_REQUEST = 1,
		PWM_STATE_WAIT_ACK = 2,
		PWM_STATE_END = 3;

	reg [2:0] pwm_state = 0;

	wire [31:0] pwm_dat_o;
	wire pwm_ack_o;
	wire pwm_stall_o;

	wb_pwm #(
		.CHANNEL_NUM(1)
	) pwm_motor (
		.wb_clk_i(clock),
		.wb_rst_i(reset),
		.wb_stb_i(pwm_state == PWM_STATE_REQUEST),
		.wb_cyc_i(pwm_state >= PWM_STATE_REQUEST
			&& pwm_state <= PWM_STATE_WAIT_ACK),
		.wb_we_i(1),
		.wb_adr_i(0),
		.wb_dat_i(32'h30),
		.wb_dat_o(pwm_dat_o),
		.wb_ack_o(pwm_ack_o),
		.wb_stall_o(pwm_stall_o),
		.pwm(pwm_motor_o)
	);

	// main state machine for PWM: issue a single duty-cycle request
	// issue responses over wishbone
	always @(posedge clock) begin
		case (pwm_state)
		PWM_STATE_REQUEST: begin
			if (!pwm_stall_o)
				pwm_state <= pwm_state + 1;
		end
		PWM_STATE_WAIT_ACK: begin
			if (pwm_ack_o)
				pwm_state <= pwm_state + 1;
		end
		PWM_STATE_END: begin
			// sleep forever
		end
		default: begin
			pwm_state <= pwm_state + 1;
		end
		endcase
	end

endmodule
