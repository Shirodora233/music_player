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
| `key_display_mode` | input | Cycle the right-side playback display mode |
| `key_self_test` | input | Long-press to enter or exit board self-test mode |
| `beep` | output | Passive buzzer output; board documentation specifies pin W19 |
| `led[31:0]` | output | Board LED outputs; `board_led_mapper` maps logical rows to schematic LED nets |
| `seg[31:0]` | output | Seven-segment A/B/C/D/E/F/G/DP lines for LED1 through LED4 |
| `seg_cs[7:0]` | output | Seven-segment digit select lines, right-to-left on the board |

Buttons are active-low. On the supplied schematic, the current allocation is
KEY8 reset, KEY7 play/pause, KEY6 stop, KEY5 parameter select, KEY4 value down,
KEY3 value up, KEY2 playback display mode, and KEY1 self-test mode. The design
and XDC both use the board's 200 MHz clock.

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
| `key_display_mode` | KEY2 | C14 | Low |
| `key_self_test` | KEY1 | E15 | Low |
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
| Row 2 | Flat flag, sharp flag, and right-aligned beat-in-bar indicator |
| Row 3 | Playback progress bar based on elapsed rhythm units |

The seven-segment display is formatted by `sevenseg_ui_formatter` and scanned by
`sevenseg_scan_controller`. The formatter treats logical digit 7 as the
leftmost position and logical digit 0 as the rightmost position. The board's
observed physical select order is `seg_cs[0]`, `[1]`, `[2]`, `[3]`, `[5]`,
`[4]`, `[7]`, `[6]` from left to right, so the scanner maps logical digits onto
that order when driving the physical digit select and segment bundle. Each
physical two-digit module has its own A/B/C/D/E/F/G/DP segment bundle in
`seg[31:0]`.

| Digits | Display |
| --- | --- |
| Left four | Current selected parameter: `S001`, `t+00`, `t-12`, `b084`, `U007`, `P-St`, `P-1L`, or `P-AL` |
| Right four | KEY2-selected playback display; these four digits blink while paused |

KEY2 cycles the right four digits through elapsed time `MM.SS`, remaining time
`MM.SS`, and bar/beat position `BBB.P`. For example, `123.1` means bar 123,
beat 1.

Long-press KEY1 to enter or exit board self-test mode. In self-test mode the
music player keeps its internal state, but the board outputs are overridden:
the LEDs scan one position at a time, the seven-segment display shows
`01234567`, and the buzzer emits a fixed diagnostic tone.

## Parameter controls

`ui_controller` manages five editable parameters. `key_next` cycles through
song, transpose, BPM, volume, and playback mode. `key_volume_down` and
`key_volume_up` decrement or increment the selected parameter. These two value
keys support long-press auto-repeat, with a faster repeat rate after a longer
hold. If no parameter key is pressed for five seconds, the UI returns to the
song display mode.

| Parameter | Range | Notes |
| --- | --- | --- |
| Song | 0 to 2 | Changing songs stops playback and returns to note 0 |
| Transpose | -12 to +12 semitones | Display spelling follows interval-based transposition |
| BPM | 30 to 250 | Default starts at the song metadata BPM |
| Volume | 0 to 7 | 0 mutes the buzzer; low nonzero levels use narrow duty cycles |
| Playback mode | Stop, one-song loop, all-song loop | Left display shows `P-St`, `P-1L`, or `P-AL` |

## Built-in songs

- Song 0: Jiaojie Smile MIDI melody
- Song 1: Old Memory MIDI melody
- Song 2: Haruhikage MIDI melody

## Song encoding

`song_rom` stores each note as a 17-bit word:

| Bits | Field | Description |
| --- | --- | --- |
| `[16]` | `rest` | 1 for a rest, 0 for a pitched note |
| `[15:13]` | `note_name` | C, D, E, F, G, A, B |
| `[12:11]` | `accidental` | flat, natural, sharp |
| `[10:7]` | `octave` | octave 0 through 8 |
| `[6:0]` | `duration_units` | duration in rhythm units; one unit is one twelfth of a quarter note |

The ROM also emits per-song metadata: note count, total duration in rhythm
units, default BPM, beats per bar, and the first beat offset. The current
playback path sends this richer note word through `pitch_processor`, which
computes both the sounding semitone pitch and the display spelling. The
transpose parameter is controlled by `ui_controller`.

Playback timing uses each song's default BPM and the note `duration_units`
field. `beat_controller` emits one pulse per rhythm unit, one pulse per
quarter-note beat, and a note-done pulse at the end of the encoded duration.
There are twelve rhythm units per quarter note, which represents both sixteenth
notes and triplet figures exactly. `music_top` counts elapsed rhythm units and
elapsed seconds while playback is running; those counters feed the LED progress
bar and seven-segment time display.

## Score conversion tool

`tools/score_to_song_rom.py` converts a Standard MIDI file or a simple text
score into a `song_rom` metadata and `case (note_index)` snippet. It does not
edit `song_rom.v` automatically; review the generated spelling and paste the
block into the desired song branch.

Example:

```powershell
python tools\score_to_song_rom.py song.mid --song-index 3 --output tmp\song3_rom.vh
```

Text score format:

```text
# title: Example
# bpm: 120
# time: 4/4
C4:12 D4:12 E4:12 R:12 F#4:24 Bb4:24
```

Durations are encoded in rhythm units. Accidentals are kept in the note spelling,
so `C#4:4` and `Db4:4` can display differently even though they sound at the
same semitone. MIDI key-signature events are used only while converting pitches
to note spellings; the generated ROM does not store a single song-level key
signature.

The pin assignments are stored in `lab_music.srcs/constrs_1/new/music.xdc`.
They are based on `xc7k325t-V2.1-out.pdf` and the supplied board photo. The
buzzer constraint is:

```tcl
set_property PACKAGE_PIN W19 [get_ports beep]
set_property IOSTANDARD LVCMOS33 [get_ports beep]
```
