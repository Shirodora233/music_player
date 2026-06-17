# Simple Music Player

## Top-level ports

| Port | Direction | Description |
| --- | --- | --- |
| `clk` | input | 200 MHz board system clock on FPGA pin AD12 |
| `rst_n` | input | Active-low reset |
| `key_play_pause` | input | Play/pause button |
| `key_stop` | input | Stop button; returns to the first note |
| `key_next` | input | Cycle the selected editable parameter |
| `key_volume_down` | input | Decrease the selected parameter |
| `key_volume_up` | input | Increase the selected parameter |
| `beep` | output | Passive buzzer output; board documentation specifies pin W19 |
| `led[31:0]` | output | Board LED outputs; `board_led_mapper` maps logical rows to schematic LED nets |
| `seg[31:0]` | output | Seven-segment A/B/C/D/E/F/G/DP lines for LED1 through LED4 |
| `seg_cs[7:0]` | output | Seven-segment digit select lines, right-to-left on the board |

Buttons are active-low. On the supplied schematic, the current allocation is
KEY8 reset, KEY7 play/pause, KEY6 stop, KEY5 parameter select, KEY4 value down,
and KEY3 value up. The design and XDC both use the board's 200 MHz clock.

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
| `seg[0]` ... `seg[31]` | LED1 ... LED4 segment pins | see XDC | High |
| `seg_cs[0]` ... `seg_cs[7]` | Eight seven-segment digit selects | see XDC | Low |

The 32 discrete LEDs are treated as four logical rows, ordered left-to-right in
the board photo. `led_panel_controller` drives the musical display and
`board_led_mapper` translates those four rows to schematic LED nets.

| Row | Display |
| --- | --- |
| Row 0 | Current note name: C, D, E, F, G, A, B on the first seven LEDs |
| Row 1 | Octave: octave 0 is all off, octaves 1 through 8 light one LED |
| Row 2 | Flat flag, sharp flag, and beat flash on the final LED |
| Row 3 | Playback progress bar based on elapsed sixteenth-note units |

The seven-segment display is driven by `sevenseg_scan_controller`. It scans the
eight digits from right to left, with `seg_cs[0]` as the rightmost digit and
`seg_cs[7]` as the leftmost digit. Each physical two-digit module has its own
A/B/C/D/E/F/G/DP segment bundle in `seg[31:0]`. The current hardware bring-up
pattern is fixed to `12345678`; the next stage replaces this with playback time
and parameter status.

## Parameter controls

`ui_controller` manages three editable parameters. `key_next` cycles through
song, transpose, and BPM. `key_volume_down` and `key_volume_up` decrement or
increment the selected parameter. If no parameter key is pressed for five
seconds, the UI returns to the song display mode.

| Parameter | Range | Notes |
| --- | --- | --- |
| Song | 0 to 1 | Changing songs stops playback and returns to note 0 |
| Transpose | -12 to +12 semitones | Display spelling follows interval-based transposition |
| BPM | 30 to 250 | Default starts at the song metadata BPM |

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
playback path sends this richer note word through `pitch_processor`, which
computes both the sounding semitone pitch and the display spelling. The
transpose parameter is controlled by `ui_controller`.

Playback timing uses each song's default BPM and the note `duration_16th` field.
`beat_controller` emits one pulse per sixteenth note, one pulse per quarter-note
beat, and a note-done pulse at the end of the encoded duration. `music_top`
counts elapsed sixteenth-note units and elapsed seconds while playback is
running; those counters feed the LED progress bar and seven-segment time
display.

The pin assignments are stored in `lab_music.srcs/constrs_1/new/music.xdc`.
They are based on `xc7k325t-V2.1-out.pdf` and the supplied board photo. The
buzzer constraint is:

```tcl
set_property PACKAGE_PIN W19 [get_ports beep]
set_property IOSTANDARD LVCMOS33 [get_ports beep]
```
