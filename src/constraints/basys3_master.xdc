## ==============================================================================
## Constraints file for Digilent Basys 3 FPGA Board (Artix-7 XC7A35T-1CPG236C)
## Project: FPGA Design Fabric & Architecture
## Author: Sujay Kandalkar
## ==============================================================================

## Clock signal (100 MHz onboard oscillator)
set_property PACKAGE_PIN W5 [get_ports clk]							
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Reset signal (Center Pushbutton BtnC / Switch SW0)
set_property PACKAGE_PIN V17 [get_ports rst]					
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## 4-bit Counter Output LEDs (LD0 to LD3)
set_property PACKAGE_PIN U16 [get_ports {counter_out[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {counter_out[0]}]
set_property PACKAGE_PIN E19 [get_ports {counter_out[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {counter_out[1]}]
set_property PACKAGE_PIN U19 [get_ports {counter_out[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {counter_out[2]}]
set_property PACKAGE_PIN V19 [get_ports {counter_out[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {counter_out[3]}]

## Configuration voltage constraints
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
