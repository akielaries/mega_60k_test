//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.12.01 
//Created Time: 2026-02-05 07:51:05
create_clock -name HCLK -period 20 -waveform {0 10} [get_ports {HCLK}]
