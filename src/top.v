module top (
    input HCLK,
    input hwRstn,
    inout [15:0] GPIO,
    inout JTAG_7_SWDIO,
    inout JTAG_9_SWDCLK,
    output LOCKUP,     // Added as output
    output HALTED   
);


    // Instantiate the Cortex-M1 core
	Gowin_EMPU_M1_Top Cortex_M1_instance(
		.LOCKUP(LOCKUP), //output LOCKUP
		.HALTED(HALTED), //output HALTED
		.GPIO(GPIO), //inout [15:0] GPIO
		.JTAG_7(JTAG_7), //inout JTAG_7
		.JTAG_9(JTAG_9), //inout JTAG_9
		.UART1RXD(UART1RXD), //input UART1RXD
		.UART1TXD(UART1TXD), //output UART1TXD
		.HCLK(HCLK), //input HCLK
		.hwRstn(hwRstn) //input hwRstn
	);



endmodule