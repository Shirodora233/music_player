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
| `led[31:0]` | output | Board LED outputs; `board_led_mapper` maps logical rows to schematic LED nets |

Buttons are active-low. On the supplied schematic, the current allocation is
KEY8 reset, KEY7 play/pause, KEY6 stop, KEY5 next song, KEY4 volume down, and
KEY3 volume up. The design and XDC both use the board's 200 MHz clock.

## Board pin allocation

| Top-level port | Board resource | FPGA pin | Active level |
| --- | --- | --- | --- |
| `clk` | CLK | AD12 | 200 MHz |
| `rst_n` | KEY8 | D11 | Low |
| `key_play_pause` | KEY7 | C11 | Low |
| `key_stop` | KEY6 | E14 | Low |
| `key_next` | KEY5 | B13 | Low |
| `key_volume_down` | KEY4 | A13 | Low |
| `key_volume_up` | KEY3 | D14 | Low |
| `beep` | BEEP | W19 | Square-wave output |
| `led[0]` ... `led[31]` | LED1 ... LED32 | see XDC | High |

For now, the original playback state display is preserved on the bottom LED row:
playing, paused, stopped, song select, and the four-step volume bar. The
`board_led_mapper` module keeps this temporary status display separate from the
physical board pin order so the full panel UI can be added later.

## Built-in songs

- Song 0: Twinkle Twinkle Little Star
- Song 1: Two Tigers

## Song encoding

`song_rom` stores each note as a 16-bit word:

| Bits | Field | Description |
| --- | --- | --- |
| `[15]` | `rest` | 1 for a rest, 0 for a pitched note |
| `[14:12]` | `note_name` | C, D, E, F, G, A, B |
| `[11:10]` | `accidental` | flat, natural, sharp |
| `[9:6]` | `octave` | octave 0 through 8 |
| `[5:0]` | `duration_16th` | duration in sixteenth-note units |

The ROM also emits per-song metadata: note count, total duration in
sixteenth-note units, default BPM, tonic, accidental, and mode. The current
playback path temporarily decodes this richer note word back into the original
tone-generator note codes; later stages use the full fields for transposition
and panel display.

The pin assignments are stored in `lab_music.srcs/constrs_1/new/music.xdc`.
They are based on `xc7k325t-V2.1-out.pdf` and the supplied board photo. The
buzzer constraint is:

```tcl
set_property PACKAGE_PIN W19 [get_ports beep]
set_property IOSTANDARD LVCMOS33 [get_ports beep]
```
