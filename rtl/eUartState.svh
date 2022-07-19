`default_nettype none
`ifndef eUartState
`define eUartState

typedef enum {
	eUartState_Idle,
	eUartState_Start,
	eUartState_Bit0,
	eUartState_Bit1,
	eUartState_Bit2,
	eUartState_Bit3,
	eUartState_Bit4,
	eUartState_Bit5,
	eUartState_Bit6,
	eUartState_Bit7,
	eUartState_Stop
} eUartState;

`endif
