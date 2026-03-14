//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.12.01 
//Created Time: 2026-02-05 14:47:11
create_clock -name hclk -period 20 -waveform {0 10} [get_ports {HCLK}]
create_clock -name swd_clk -period 200 -waveform {0 100} [get_ports {JTAG_9_SWDCLK}]

create_clock -name ddr3_mem_clk -period 5 -waveform {0 2.5} [get_pins {u_Gowin_PLL/u_pll/PLLA_inst/CLKOUT2}]
create_clock -name ddr3_sys_clk -period 20 -waveform {0 10} [get_pins {Cortex_M1_instance/u_GowinCM1AhbExtWrapper/u_GowinCM1AhbExt/u_ahb_ddr3/u_ddr3/gw3_top/u_ddr_phy_top/fclkdiv/CLKOUT}]

// RGMII Ethernet clocks
// gtx_clk_125: 125 MHz TX clock from PLL clkout0
// rgmii_rxc: 125 MHz RX clock from PHY on port pin (no PLL substitute on 60K)
create_clock -name gtx_clk_125 -period 8 -waveform {0 4} [get_pins {u_Gowin_PLL/u_pll/PLLA_inst/CLKOUT0}]
create_clock -name rgmii_rxc   -period 8 -waveform {0 4} [get_ports {RGMII_RXC}]

set_clock_groups -exclusive -group [get_clocks {hclk}] -group [get_clocks {swd_clk}] -group [get_clocks {ddr3_sys_clk}] -group [get_clocks {ddr3_mem_clk}] -group [get_clocks {gtx_clk_125}] -group [get_clocks {rgmii_rxc}]