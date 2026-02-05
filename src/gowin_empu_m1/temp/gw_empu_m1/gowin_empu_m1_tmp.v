//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.12.01
//IP Version: 2.1
//Part Number: GW5AT-LV60PG484AC2/I1
//Device: GW5AT-60
//Device Version: B
//Created Time: Thu Feb  5 08:34:21 2026

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	Gowin_EMPU_M1_Top your_instance_name(
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

//--------Copy end-------------------
