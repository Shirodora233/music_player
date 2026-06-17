## Simple music player constraints
## FPGA: XC7K325T-2FFG900
## Pin source: board pin-assignment workbook supplied with the project

## 200 MHz board clock: CLK / AD12
set_property PACKAGE_PIN AD12 [get_ports clk]
set_property IOSTANDARD LVCMOS18 [get_ports clk]
create_clock -period 5.000 -name sys_clk [get_ports clk]

## Active-low buttons: pressed = 0, released = 1
## KEY1: system reset
set_property PACKAGE_PIN D11 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

## KEY2: play / pause
set_property PACKAGE_PIN C11 [get_ports key_play_pause]
set_property IOSTANDARD LVCMOS33 [get_ports key_play_pause]

## KEY3: stop
set_property PACKAGE_PIN E14 [get_ports key_stop]
set_property IOSTANDARD LVCMOS33 [get_ports key_stop]

## KEY4: next song
set_property PACKAGE_PIN B13 [get_ports key_next]
set_property IOSTANDARD LVCMOS33 [get_ports key_next]

## KEY5: volume down (level 0 is mute)
set_property PACKAGE_PIN A13 [get_ports key_volume_down]
set_property IOSTANDARD LVCMOS33 [get_ports key_volume_down]

## KEY6: volume up
set_property PACKAGE_PIN D14 [get_ports key_volume_up]
set_property IOSTANDARD LVCMOS33 [get_ports key_volume_up]

## Passive buzzer: BEEP / W19
set_property PACKAGE_PIN W19 [get_ports beep]
set_property IOSTANDARD LVCMOS33 [get_ports beep]

## Status LEDs: LED1 through LED8, active-high
set_property PACKAGE_PIN G24 [get_ports {led[0]}]
set_property PACKAGE_PIN E24 [get_ports {led[1]}]
set_property PACKAGE_PIN C24 [get_ports {led[2]}]
set_property PACKAGE_PIN E25 [get_ports {led[3]}]
set_property PACKAGE_PIN C26 [get_ports {led[4]}]
set_property PACKAGE_PIN F26 [get_ports {led[5]}]
set_property PACKAGE_PIN G25 [get_ports {led[6]}]
set_property PACKAGE_PIN E29 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

## Use slow output edges for low-frequency LEDs and buzzer signals.
set_property SLEW SLOW [get_ports beep]
set_property SLEW SLOW [get_ports {led[*]}]
