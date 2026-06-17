## Simple music player constraints
## FPGA: XC7K325T-2FFG900
## Pin source: xc7k325t-V2.1-out.pdf plus supplied board photo

## 200 MHz board clock: CLK / AD12
set_property PACKAGE_PIN AD12 [get_ports clk]
set_property IOSTANDARD LVCMOS18 [get_ports clk]
create_clock -period 5.000 -name sys_clk [get_ports clk]

## Active-low buttons: pressed = 0, released = 1
## Schematic KEY8: system reset
set_property PACKAGE_PIN D11 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

## Schematic KEY7: play / pause
set_property PACKAGE_PIN C11 [get_ports key_play_pause]
set_property IOSTANDARD LVCMOS33 [get_ports key_play_pause]

## Schematic KEY6: stop
set_property PACKAGE_PIN E14 [get_ports key_stop]
set_property IOSTANDARD LVCMOS33 [get_ports key_stop]

## Schematic KEY5: next song
set_property PACKAGE_PIN B13 [get_ports key_next]
set_property IOSTANDARD LVCMOS33 [get_ports key_next]

## Schematic KEY4: volume down (level 0 is mute)
set_property PACKAGE_PIN A13 [get_ports key_volume_down]
set_property IOSTANDARD LVCMOS33 [get_ports key_volume_down]

## Schematic KEY3: volume up
set_property PACKAGE_PIN D14 [get_ports key_volume_up]
set_property IOSTANDARD LVCMOS33 [get_ports key_volume_up]

## Passive buzzer: BEEP / W19
set_property PACKAGE_PIN W19 [get_ports beep]
set_property IOSTANDARD LVCMOS33 [get_ports beep]

## Board LEDs: led[0] is schematic LED1; led[31] is schematic LED32.
## The board_led_mapper module translates photo rows/columns into this net order.
set_property PACKAGE_PIN F12 [get_ports {led[0]}]
set_property PACKAGE_PIN E30 [get_ports {led[1]}]
set_property PACKAGE_PIN F23 [get_ports {led[2]}]
set_property PACKAGE_PIN D23 [get_ports {led[3]}]
set_property PACKAGE_PIN A27 [get_ports {led[4]}]
set_property PACKAGE_PIN A26 [get_ports {led[5]}]
set_property PACKAGE_PIN B25 [get_ports {led[6]}]
set_property PACKAGE_PIN A25 [get_ports {led[7]}]
set_property PACKAGE_PIN E28 [get_ports {led[8]}]
set_property PACKAGE_PIN G28 [get_ports {led[9]}]
set_property PACKAGE_PIN D26 [get_ports {led[10]}]
set_property PACKAGE_PIN D24 [get_ports {led[11]}]
set_property PACKAGE_PIN E29 [get_ports {led[12]}]
set_property PACKAGE_PIN F26 [get_ports {led[13]}]
set_property PACKAGE_PIN G25 [get_ports {led[14]}]
set_property PACKAGE_PIN C26 [get_ports {led[15]}]
set_property PACKAGE_PIN F25 [get_ports {led[16]}]
set_property PACKAGE_PIN E26 [get_ports {led[17]}]
set_property PACKAGE_PIN D28 [get_ports {led[18]}]
set_property PACKAGE_PIN C30 [get_ports {led[19]}]
set_property PACKAGE_PIN A23 [get_ports {led[20]}]
set_property PACKAGE_PIN B24 [get_ports {led[21]}]
set_property PACKAGE_PIN B27 [get_ports {led[22]}]
set_property PACKAGE_PIN B23 [get_ports {led[23]}]
set_property PACKAGE_PIN C29 [get_ports {led[24]}]
set_property PACKAGE_PIN C25 [get_ports {led[25]}]
set_property PACKAGE_PIN E23 [get_ports {led[26]}]
set_property PACKAGE_PIN G23 [get_ports {led[27]}]
set_property PACKAGE_PIN E25 [get_ports {led[28]}]
set_property PACKAGE_PIN E24 [get_ports {led[29]}]
set_property PACKAGE_PIN C24 [get_ports {led[30]}]
set_property PACKAGE_PIN G24 [get_ports {led[31]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

## Use slow output edges for low-frequency LEDs and buzzer signals.
set_property SLEW SLOW [get_ports beep]
set_property SLEW SLOW [get_ports {led[*]}]
