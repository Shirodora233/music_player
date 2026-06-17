# Simple Music Player

## Top-level ports

| Port | Direction | Description |
| --- | --- | --- |
| `clk` | input | 200 MHz board system clock on FPGA pin AD12 |
| `rst_n` | input | Active-low reset |
| `key_play_pause` | input | Play/pause button |
| `key_stop` | input | Stop button; returns to the first note |
| `key_next` | input | Switch between the two built-in songs |
| `key_volume_down` | input | Reduce volume; level 0 is mute |
| `key_volume_up` | input | Increase volume |
| `beep` | output | Passive buzzer output; board documentation specifies pin W19 |
| `led[7:0]` | output | Playback state, song selection, and note code |

Buttons are active-low. The current allocation is KEY1 reset, KEY2 play/pause,
KEY3 stop, KEY4 next song, KEY5 volume down, and KEY6 volume up. The design and
XDC both use the board's 200 MHz clock.

## Board pin allocation

| Top-level port | Board resource | FPGA pin | Active level |
| --- | --- | --- | --- |
| `clk` | CLK | AD12 | 200 MHz |
| `rst_n` | KEY1 | D11 | Low |
| `key_play_pause` | KEY2 | C11 | Low |
| `key_stop` | KEY3 | E14 | Low |
| `key_next` | KEY4 | B13 | Low |
| `key_volume_down` | KEY5 | A13 | Low |
| `key_volume_up` | KEY6 | D14 | Low |
| `beep` | BEEP | W19 | Square-wave output |
| `led[0]` | LED1 | G24 | High |
| `led[1]` | LED2 | E24 | High |
| `led[2]` | LED3 | C24 | High |
| `led[3]` | LED4 | E25 | High |
| `led[4]` | LED5 | C26 | High |
| `led[5]` | LED6 | F26 | High |
| `led[6]` | LED7 | G25 | High |
| `led[7]` | LED8 | E29 | High |

LED1 indicates playing, LED2 paused, LED3 stopped, and LED4 selects song 2.
LED5 through LED8 form a volume bar. The volume levels are mute, 12.5%, 25%,
37.5%, and 50%. For a passive buzzer, 50% duty cycle gives the maximum AC drive.

## Built-in songs

- Song 0: Twinkle Twinkle Little Star
- Song 1: Two Tigers

The pin assignments are stored in `lab_music.srcs/constrs_1/new/music.xdc`.
They were mapped from `ALU模块上板测试引脚表.xlsx`. The buzzer constraint is:

```tcl
set_property PACKAGE_PIN W19 [get_ports beep]
set_property IOSTANDARD LVCMOS33 [get_ports beep]
```
