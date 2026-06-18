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

## Schematic KEY5: parameter select
set_property PACKAGE_PIN B13 [get_ports key_next]
set_property IOSTANDARD LVCMOS33 [get_ports key_next]

## Schematic KEY4: selected parameter down
set_property PACKAGE_PIN A13 [get_ports key_volume_down]
set_property IOSTANDARD LVCMOS33 [get_ports key_volume_down]

## Schematic KEY3: selected parameter up
set_property PACKAGE_PIN D14 [get_ports key_volume_up]
set_property IOSTANDARD LVCMOS33 [get_ports key_volume_up]

## Schematic KEY2: playback display mode select
set_property PACKAGE_PIN C14 [get_ports key_display_mode]
set_property IOSTANDARD LVCMOS33 [get_ports key_display_mode]

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

## Seven-segment modules. Segment bit order inside each module is
## A, B, C, D, E, F, G, DP. Board-observed digit select order is not
## monotonic across all modules. The visible left-to-right digit order is
## seg_cs[0], [1], [2], [3], [5], [4], [7], [6].
## sevenseg_scan_controller maps logical digits onto that physical order.
set_property PACKAGE_PIN K14 [get_ports {seg[0]}]
set_property PACKAGE_PIN L15 [get_ports {seg[1]}]
set_property PACKAGE_PIN H16 [get_ports {seg[2]}]
set_property PACKAGE_PIN J16 [get_ports {seg[3]}]
set_property PACKAGE_PIN K16 [get_ports {seg[4]}]
set_property PACKAGE_PIN K15 [get_ports {seg[5]}]
set_property PACKAGE_PIN L12 [get_ports {seg[6]}]
set_property PACKAGE_PIN K13 [get_ports {seg[7]}]
set_property PACKAGE_PIN J13 [get_ports {seg[8]}]
set_property PACKAGE_PIN H11 [get_ports {seg[9]}]
set_property PACKAGE_PIN J12 [get_ports {seg[10]}]
set_property PACKAGE_PIN L11 [get_ports {seg[11]}]
set_property PACKAGE_PIN J11 [get_ports {seg[12]}]
set_property PACKAGE_PIN H12 [get_ports {seg[13]}]
set_property PACKAGE_PIN F13 [get_ports {seg[14]}]
set_property PACKAGE_PIN G13 [get_ports {seg[15]}]
set_property PACKAGE_PIN AG28 [get_ports {seg[16]}]
set_property PACKAGE_PIN AG27 [get_ports {seg[17]}]
set_property PACKAGE_PIN AF27 [get_ports {seg[18]}]
set_property PACKAGE_PIN AC26 [get_ports {seg[19]}]
set_property PACKAGE_PIN AF26 [get_ports {seg[20]}]
set_property PACKAGE_PIN AH27 [get_ports {seg[21]}]
set_property PACKAGE_PIN AJ26 [get_ports {seg[22]}]
set_property PACKAGE_PIN AF30 [get_ports {seg[23]}]
set_property PACKAGE_PIN AK26 [get_ports {seg[24]}]
set_property PACKAGE_PIN AJ29 [get_ports {seg[25]}]
set_property PACKAGE_PIN AJ27 [get_ports {seg[26]}]
set_property PACKAGE_PIN AE30 [get_ports {seg[27]}]
set_property PACKAGE_PIN AG30 [get_ports {seg[28]}]
set_property PACKAGE_PIN AK30 [get_ports {seg[29]}]
set_property PACKAGE_PIN AK28 [get_ports {seg[30]}]
set_property PACKAGE_PIN AK29 [get_ports {seg[31]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[*]}]

set_property PACKAGE_PIN AH30 [get_ports {seg_cs[0]}]
set_property PACKAGE_PIN AJ28 [get_ports {seg_cs[1]}]
set_property PACKAGE_PIN AF28 [get_ports {seg_cs[2]}]
set_property PACKAGE_PIN AH26 [get_ports {seg_cs[3]}]
set_property PACKAGE_PIN K11 [get_ports {seg_cs[4]}]
set_property PACKAGE_PIN J14 [get_ports {seg_cs[5]}]
set_property PACKAGE_PIN L16 [get_ports {seg_cs[6]}]
set_property PACKAGE_PIN L13 [get_ports {seg_cs[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_cs[*]}]

## Use slow output edges for low-frequency LEDs and buzzer signals.
set_property SLEW SLOW [get_ports beep]
set_property SLEW SLOW [get_ports {led[*]}]
set_property SLEW SLOW [get_ports {seg[*]}]
set_property SLEW SLOW [get_ports {seg_cs[*]}]
