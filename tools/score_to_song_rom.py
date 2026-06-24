#!/usr/bin/env python3
"""Convert a simple score text file or a Standard MIDI file into song_rom snippets."""

from __future__ import annotations

import argparse
import dataclasses
import pathlib
import re
import struct
import sys
from typing import List, Optional, Sequence, Tuple


ACCIDENTAL = {"b": "ACC_FLAT", "": "ACC_NATURAL", "#": "ACC_SHARP"}
UNITS_PER_QUARTER = 12

SHARP_SPELLING = [
    ("C", ""), ("C", "#"), ("D", ""), ("D", "#"),
    ("E", ""), ("F", ""), ("F", "#"), ("G", ""),
    ("G", "#"), ("A", ""), ("A", "#"), ("B", ""),
]
FLAT_SPELLING = [
    ("C", ""), ("D", "b"), ("D", ""), ("E", "b"),
    ("E", ""), ("F", ""), ("G", "b"), ("G", ""),
    ("A", "b"), ("A", ""), ("B", "b"), ("B", ""),
]


@dataclasses.dataclass
class SongNote:
    rest: bool
    name: str = "C"
    accidental: str = ""
    octave: int = 4
    duration: int = 4


@dataclasses.dataclass
class Song:
    title: str
    notes: List[SongNote]
    bpm: int = 120
    beats_per_bar: int = 4
    first_beat: int = 0

    @property
    def total_duration(self) -> int:
        return sum(note.duration for note in self.notes)


@dataclasses.dataclass
class MidiNote:
    start: int
    end: int
    pitch: int
    track: int


@dataclasses.dataclass
class KeyEvent:
    tick: int
    sf: int
    minor: int


def read_varlen(data: bytes, pos: int) -> Tuple[int, int]:
    value = 0
    while True:
        if pos >= len(data):
            raise ValueError("unexpected end of MIDI variable-length value")
        byte = data[pos]
        pos += 1
        value = (value << 7) | (byte & 0x7F)
        if not (byte & 0x80):
            return value, pos


def parse_midi(path: pathlib.Path) -> Song:
    data = path.read_bytes()
    if data[:4] != b"MThd":
        raise ValueError("not a Standard MIDI file")
    header_len = struct.unpack(">I", data[4:8])[0]
    fmt, track_count, division = struct.unpack(">HHH", data[8:14])
    if division & 0x8000:
        raise ValueError("SMPTE time division is not supported")

    pos = 8 + header_len
    tempo_us_per_quarter = 500000
    tempo_seen = False
    beats_per_bar = 4
    key_events: List[KeyEvent] = [KeyEvent(0, 0, 0)]
    track_names: List[str] = []
    all_notes: List[MidiNote] = []

    for track_index in range(track_count):
        if data[pos:pos + 4] != b"MTrk":
            raise ValueError(f"missing MTrk header at track {track_index}")
        length = struct.unpack(">I", data[pos + 4:pos + 8])[0]
        track_data = data[pos + 8:pos + 8 + length]
        pos += 8 + length

        abs_tick = 0
        cursor = 0
        running_status: Optional[int] = None
        active: dict[Tuple[int, int], List[int]] = {}
        track_name = f"track{track_index}"

        while cursor < len(track_data):
            delta, cursor = read_varlen(track_data, cursor)
            abs_tick += delta
            status = track_data[cursor]
            if status & 0x80:
                cursor += 1
                running_status = status
            elif running_status is None:
                raise ValueError("running status used before a status byte")
            else:
                status = running_status

            if status == 0xFF:
                meta_type = track_data[cursor]
                cursor += 1
                meta_len, cursor = read_varlen(track_data, cursor)
                payload = track_data[cursor:cursor + meta_len]
                cursor += meta_len
                if meta_type == 0x03 and payload:
                    try:
                        track_name = payload.decode("utf-8")
                    except UnicodeDecodeError:
                        track_name = payload.decode("latin1", errors="replace")
                elif meta_type == 0x51 and len(payload) == 3 and not tempo_seen:
                    tempo_us_per_quarter = int.from_bytes(payload, "big")
                    tempo_seen = True
                elif meta_type == 0x58 and len(payload) >= 2:
                    beats_per_bar = payload[0]
                elif meta_type == 0x59 and len(payload) >= 2:
                    key_events.append(KeyEvent(abs_tick, struct.unpack("b", payload[:1])[0], payload[1]))
                continue

            if status in (0xF0, 0xF7):
                sysex_len, cursor = read_varlen(track_data, cursor)
                cursor += sysex_len
                continue

            event_type = status & 0xF0
            channel = status & 0x0F
            data_len = 1 if event_type in (0xC0, 0xD0) else 2
            event_data = track_data[cursor:cursor + data_len]
            cursor += data_len

            if channel == 9 or event_type not in (0x80, 0x90):
                continue

            pitch = event_data[0]
            velocity = event_data[1]
            key = (channel, pitch)
            if event_type == 0x90 and velocity > 0:
                active.setdefault(key, []).append(abs_tick)
            elif key in active and active[key]:
                start = active[key].pop(0)
                if abs_tick > start:
                    all_notes.append(MidiNote(start, abs_tick, pitch, track_index))

        track_names.append(track_name)

    if not all_notes:
        raise ValueError("MIDI file contains no pitched note events")

    chosen_track = max(
        sorted({note.track for note in all_notes}),
        key=lambda tr: sum(1 for note in all_notes if note.track == tr),
    )
    notes = [note for note in all_notes if note.track == chosen_track]
    notes.sort(key=lambda note: (note.start, -note.pitch, note.end))

    if division % UNITS_PER_QUARTER != 0:
        raise ValueError(
            f"MIDI division {division} is not divisible by {UNITS_PER_QUARTER}"
        )

    quant = max(1, division // UNITS_PER_QUARTER)
    key_events.sort(key=lambda event: event.tick)
    song_notes: List[SongNote] = []
    cursor_units = 0
    used_starts: set[int] = set()

    for note in notes:
        start_units = int(round(note.start / quant))
        if start_units in used_starts:
            continue
        used_starts.add(start_units)
        duration_units = max(1, int(round((note.end - note.start) / quant)))
        if start_units > cursor_units:
            append_duration(song_notes, SongNote(True, duration=start_units - cursor_units))
        prefer_flats = key_at_tick(note.start, key_events).sf < 0
        name, accidental = spell_midi_pitch(note.pitch, prefer_flats)
        octave = max(0, min(8, note.pitch // 12 - 1))
        append_duration(song_notes, SongNote(False, name, accidental, octave, duration_units))
        cursor_units = max(cursor_units, start_units + duration_units)

    bpm = int(round(60000000 / tempo_us_per_quarter))
    title = track_names[chosen_track] if chosen_track < len(track_names) else path.stem
    return Song(
        title=title or path.stem,
        notes=song_notes,
        bpm=max(30, min(250, bpm)),
        beats_per_bar=max(2, min(4, beats_per_bar)),
    )


def key_at_tick(tick: int, key_events: Sequence[KeyEvent]) -> KeyEvent:
    current = key_events[0]
    for event in key_events:
        if event.tick > tick:
            break
        current = event
    return current


def append_duration(notes: List[SongNote], note: SongNote) -> None:
    remaining = note.duration
    while remaining > 0:
        chunk = min(127, remaining)
        notes.append(dataclasses.replace(note, duration=chunk))
        remaining -= chunk


def spell_midi_pitch(pitch: int, prefer_flats: bool) -> Tuple[str, str]:
    table = FLAT_SPELLING if prefer_flats else SHARP_SPELLING
    return table[pitch % 12]


def parse_text_score(path: pathlib.Path) -> Song:
    title = path.stem
    bpm = 120
    beats_per_bar = 4
    first_beat = 0
    notes: List[SongNote] = []

    token_re = re.compile(r"^([A-Ga-g])([#b]?)([0-8]):([0-9]+)$")
    rest_re = re.compile(r"^[Rr]:([0-9]+)$")

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("#"):
            line = line[1:].strip()
            if ":" in line:
                key, value = [part.strip() for part in line.split(":", 1)]
                key_l = key.lower()
                if key_l == "title":
                    title = value
                elif key_l == "bpm":
                    bpm = int(value)
                elif key_l == "time":
                    beats_per_bar = int(value.split("/", 1)[0])
                elif key_l == "first_beat":
                    first_beat = max(0, int(value) - 1)
            continue

        for token in re.split(r"[\s,]+", line):
            if not token:
                continue
            rest_match = rest_re.match(token)
            if rest_match:
                append_duration(notes, SongNote(True, duration=int(rest_match.group(1))))
                continue
            match = token_re.match(token)
            if not match:
                raise ValueError(f"unrecognized score token: {token}")
            name, accidental, octave, duration = match.groups()
            append_duration(
                notes,
                SongNote(False, name.upper(), accidental, int(octave), int(duration)),
            )

    if not notes:
        raise ValueError("text score contains no notes")
    return Song(title, notes, max(30, min(250, bpm)), max(2, min(4, beats_per_bar)),
                max(0, min(3, first_beat)))


def note_expr(note: SongNote) -> str:
    if note.duration < 1 or note.duration > 127:
        raise ValueError(f"duration out of 7-bit range after splitting: {note.duration}")
    if note.rest:
        return f"rest(7'd{note.duration})"
    return (
        f"note(N_{note.name}, {ACCIDENTAL[note.accidental]}, "
        f"4'd{note.octave}, 7'd{note.duration})"
    )


def metadata_expr(song: Song, song_index: int) -> str:
    return "\n".join([
        f"        end else if (song_select == 2'd{song_index}) begin",
        f"            // Song {song_index}: {song.title}",
        f"            song_length         = 8'd{len(song.notes)};",
        f"            total_duration_units = 16'd{song.total_duration};",
        f"            default_bpm         = 8'd{song.bpm};",
        f"            beats_per_bar       = 3'd{song.beats_per_bar};",
        f"            first_beat_in_bar   = 2'd{song.first_beat};",
        "            case (note_index)",
    ])


def emit_song(song: Song, song_index: int) -> str:
    if len(song.notes) > 255:
        raise ValueError("song_rom note_index is 8-bit; split or shorten the song")
    lines = [metadata_expr(song, song_index)]
    for idx, note in enumerate(song.notes):
        lines.append(f"                8'd{idx}: note_word = {note_expr(note)};")
    lines.append("                default: note_word = rest(DUR_QUARTER);")
    lines.append("            endcase")
    lines.append("        end")
    return "\n".join(lines)


def load_song(path: pathlib.Path, force_format: Optional[str]) -> Song:
    fmt = force_format
    if fmt is None:
        suffix = path.suffix.lower()
        fmt = "midi" if suffix in (".mid", ".midi") else "text"
    if fmt == "midi":
        return parse_midi(path)
    if fmt == "text":
        return parse_text_score(path)
    raise ValueError(f"unsupported format: {fmt}")


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=pathlib.Path, help="MIDI file or text score")
    parser.add_argument("--format", choices=["midi", "text"], help="override input format")
    parser.add_argument("--song-index", type=int, default=3, help="song_select value for the emitted block")
    parser.add_argument("--title", help="override song title in the generated comment")
    parser.add_argument("--output", type=pathlib.Path, help="write snippet to a file instead of stdout")
    args = parser.parse_args(argv)

    try:
        song = load_song(args.input, args.format)
        if args.title:
            song.title = args.title
        snippet = emit_song(song, args.song_index)
    except Exception as exc:  # pragma: no cover - CLI boundary
        print(f"error: {exc}", file=sys.stderr)
        return 1

    if args.output:
        args.output.write_text(snippet + "\n", encoding="utf-8")
    else:
        print(snippet)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
