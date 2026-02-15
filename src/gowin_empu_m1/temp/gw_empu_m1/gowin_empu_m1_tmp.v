//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.12.01
//IP Version: 2.1
//Part Number: GW5AT-LV60PG484AC2/I1
//Device: GW5AT-60
//Device Version: B
//Created Time: Sun Feb 15 11:04:26 2026

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
		.AHB1HRDATA(AHB1HRDATA), //input [31:0] AHB1HRDATA
		.AHB1HREADYOUT(AHB1HREADYOUT), //input AHB1HREADYOUT
		.AHB1HRESP(AHB1HRESP), //input [1:0] AHB1HRESP
		.AHB1HTRANS(AHB1HTRANS), //output [1:0] AHB1HTRANS
		.AHB1HBURST(AHB1HBURST), //output [2:0] AHB1HBURST
		.AHB1HPROT(AHB1HPROT), //output [3:0] AHB1HPROT
		.AHB1HSIZE(AHB1HSIZE), //output [2:0] AHB1HSIZE
		.AHB1HWRITE(AHB1HWRITE), //output AHB1HWRITE
		.AHB1HREADYMUX(AHB1HREADYMUX), //output AHB1HREADYMUX
		.AHB1HMASTER(AHB1HMASTER), //output [3:0] AHB1HMASTER
		.AHB1HMASTLOCK(AHB1HMASTLOCK), //output AHB1HMASTLOCK
		.AHB1HADDR(AHB1HADDR), //output [31:0] AHB1HADDR
		.AHB1HWDATA(AHB1HWDATA), //output [31:0] AHB1HWDATA
		.AHB1HSEL(AHB1HSEL), //output AHB1HSEL
		.AHB1HCLK(AHB1HCLK), //output AHB1HCLK
		.AHB1HRESET(AHB1HRESET), //output AHB1HRESET
		.HCLK(HCLK), //input HCLK
		.hwRstn(hwRstn) //input hwRstn
	);

//--------Copy end-------------------
