`timescale 1ns / 1ps

module music_top #(
    parameter integer CLK_FREQ_HZ    = 200_000_000,
    parameter integer NOTE_GAP_MS    = 20,
    parameter integer DEBOUNCE_MS    = 20,
    parameter integer SELF_TEST_LONG_PRESS_MS = 1000,
    parameter integer KEY_ACTIVE_LOW = 1
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       key_play_pause,
    input  wire       key_stop,
    input  wire       key_next,
    input  wire       key_volume_down,
    input  wire       key_volume_up,
    input  wire       key_display_mode,
    input  wire       key_self_test,
    output wire        beep,
    output wire [31:0] led,
    output wire [31:0] seg,
    output wire [7:0]  seg_cs
);

    wire play_key_level;
    wire stop_key_level;
    wire next_key_level;
    wire volume_down_key_level;
    wire volume_up_key_level;
    wire display_mode_key_level;
    wire self_test_key_level;
    wire play_pressed;
    wire stop_pressed;
    wire next_pressed;
    wire volume_down_key_state;
    wire volume_up_key_state;
    wire volume_down_single_pressed;
    wire volume_up_single_pressed;
    wire volume_down_pressed;
    wire volume_up_pressed;
    wire display_mode_pressed;
    wire self_test_key_state;
    wire self_test_toggle_pulse;

    wire [1:0] selected_song;
    wire song_changed;
    wire [7:0] note_index;
    wire [15:0] note_word;
    wire note_is_rest;
    wire [5:0] duration_units;
    wire signed [5:0] transpose_semitones;
    wire [7:0] current_bpm;
    wire [7:0] semitone_pitch;
    wire [2:0] display_note_name;
    wire [1:0] display_accidental;
    wire [3:0] display_octave;
    wire [7:0] song_length;
    wire [15:0] total_duration_units;
    wire [7:0] default_bpm;
    wire [2:0] beats_per_bar;
    wire [1:0] first_beat_in_bar;
    wire [2:0] safe_beats_per_bar;
    wire [1:0] safe_first_beat_in_bar;
    wire note_done;
    wire unit_pulse;
    wire beat_pulse;
    wire tone_enable;
    wire song_wrap;
    wire playback_timing_clear;
    wire playing;
    wire paused;
    wire stopped;
    wire [2:0] edit_mode;
    wire [2:0] volume_level;
    wire [1:0] playback_mode;
    wire auto_song_changed;
    wire auto_next_song;
    wire [7:0] led_row0;
    wire [7:0] led_row1;
    wire [7:0] led_row2;
    wire [7:0] led_row3;
    wire [31:0] music_led;
    wire [31:0] self_test_led;
    wire [7:0] selected_song_index;
    wire [39:0] sevenseg_glyphs;
    wire [7:0] sevenseg_decimal_points;
    wire [7:0] sevenseg_blank;
    wire [39:0] self_test_glyphs;
    wire [7:0] self_test_decimal_points;
    wire [7:0] self_test_blank;
    wire [39:0] active_sevenseg_glyphs;
    wire [7:0] active_sevenseg_decimal_points;
    wire [7:0] active_sevenseg_blank;
    wire music_beep;
    wire self_test_beep;
    wire [7:0] safe_bpm;
    wire [31:0] total_seconds_numerator;
    wire [15:0] total_duration_seconds;
    wire [15:0] remaining_seconds;
    wire [2:0] current_beat_number;
    reg [15:0] elapsed_units;
    reg [15:0] elapsed_seconds;
    reg [31:0] second_tick_count;
    reg [1:0] beat_in_bar;
    reg [9:0] current_bar_number;
    reg [1:0] playback_display_mode;
    reg self_test_active;

    localparam [31:0] SECOND_TICKS = CLK_FREQ_HZ;
    localparam [1:0] DISPLAY_ELAPSED = 2'd0;
    localparam [1:0] DISPLAY_REMAIN  = 2'd1;
    localparam [1:0] DISPLAY_BAR     = 2'd2;

    assign selected_song_index = {6'd0, selected_song};
    assign safe_beats_per_bar =
        ((beats_per_bar >= 3'd2) && (beats_per_bar <= 3'd4)) ?
        beats_per_bar : 3'd4;
    assign safe_first_beat_in_bar =
        ({1'b0, first_beat_in_bar} < safe_beats_per_bar) ?
        first_beat_in_bar : 2'd0;
    assign safe_bpm = (current_bpm == 0) ? 8'd120 : current_bpm;
    assign total_seconds_numerator =
        ({16'd0, total_duration_units} * 32'd10) + {24'd0, safe_bpm} - 32'd1;
    assign total_duration_seconds = total_seconds_numerator / safe_bpm;
    assign remaining_seconds =
        (total_duration_seconds > elapsed_seconds) ?
        (total_duration_seconds - elapsed_seconds) : 16'd0;
    assign current_beat_number = {1'b0, beat_in_bar} + 3'd1;

    assign play_key_level = KEY_ACTIVE_LOW ? ~key_play_pause : key_play_pause;
    assign stop_key_level = KEY_ACTIVE_LOW ? ~key_stop       : key_stop;
    assign next_key_level = KEY_ACTIVE_LOW ? ~key_next       : key_next;
    assign volume_down_key_level = KEY_ACTIVE_LOW ? ~key_volume_down : key_volume_down;
    assign volume_up_key_level   = KEY_ACTIVE_LOW ? ~key_volume_up   : key_volume_up;
    assign display_mode_key_level = KEY_ACTIVE_LOW ? ~key_display_mode : key_display_mode;
    assign self_test_key_level = KEY_ACTIVE_LOW ? ~key_self_test : key_self_test;
    assign led = self_test_active ? self_test_led : music_led;
    assign beep = self_test_active ? self_test_beep : music_beep;
    assign active_sevenseg_glyphs =
        self_test_active ? self_test_glyphs : sevenseg_glyphs;
    assign active_sevenseg_decimal_points =
        self_test_active ? self_test_decimal_points : sevenseg_decimal_points;
    assign active_sevenseg_blank =
        self_test_active ? self_test_blank : sevenseg_blank;

    button_debounce #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u_debounce_play (
        .clk(clk),
        .rst_n(rst_n),
        .key_in(play_key_level),
        .key_state(),
        .key_pressed(play_pressed)
    );

    button_debounce #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u_debounce_stop (
        .clk(clk),
        .rst_n(rst_n),
        .key_in(stop_key_level),
        .key_state(),
        .key_pressed(stop_pressed)
    );

    button_debounce #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u_debounce_next (
        .clk(clk),
        .rst_n(rst_n),
        .key_in(next_key_level),
        .key_state(),
        .key_pressed(next_pressed)
    );

    button_debounce #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u_debounce_volume_down (
        .clk(clk),
        .rst_n(rst_n),
        .key_in(volume_down_key_level),
        .key_state(volume_down_key_state),
        .key_pressed(volume_down_single_pressed)
    );

    button_debounce #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u_debounce_volume_up (
        .clk(clk),
        .rst_n(rst_n),
        .key_in(volume_up_key_level),
        .key_state(volume_up_key_state),
        .key_pressed(volume_up_single_pressed)
    );

    key_repeat #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) u_repeat_volume_down (
        .clk(clk),
        .rst_n(rst_n),
        .key_state(volume_down_key_state),
        .key_pressed(volume_down_single_pressed),
        .repeat_pressed(volume_down_pressed)
    );

    key_repeat #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) u_repeat_volume_up (
        .clk(clk),
        .rst_n(rst_n),
        .key_state(volume_up_key_state),
        .key_pressed(volume_up_single_pressed),
        .repeat_pressed(volume_up_pressed)
    );

    button_debounce #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u_debounce_display_mode (
        .clk(clk),
        .rst_n(rst_n),
        .key_in(display_mode_key_level),
        .key_state(),
        .key_pressed(display_mode_pressed)
    );

    button_debounce #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u_debounce_self_test (
        .clk(clk),
        .rst_n(rst_n),
        .key_in(self_test_key_level),
        .key_state(self_test_key_state),
        .key_pressed()
    );

    long_press_toggle #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .LONG_PRESS_MS(SELF_TEST_LONG_PRESS_MS)
    ) u_self_test_long_press (
        .clk(clk),
        .rst_n(rst_n),
        .key_state(self_test_key_state),
        .toggle_pulse(self_test_toggle_pulse)
    );

    ui_controller #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .SONG_COUNT(3)
    ) u_ui_controller (
        .clk(clk),
        .rst_n(rst_n),
        .next_pressed(next_pressed),
        .value_down_pressed(volume_down_pressed),
        .value_up_pressed(volume_up_pressed),
        .auto_next_song(auto_next_song),
        .default_bpm(default_bpm),
        .selected_song(selected_song),
        .transpose_semitones(transpose_semitones),
        .current_bpm(current_bpm),
        .volume_level(volume_level),
        .playback_mode(playback_mode),
        .edit_mode(edit_mode),
        .song_changed(song_changed),
        .auto_song_changed(auto_song_changed)
    );

    player_controller u_player (
        .clk(clk),
        .rst_n(rst_n),
        .play_pause_pressed(play_pressed),
        .stop_pressed(stop_pressed),
        .song_changed(song_changed),
        .auto_song_changed(auto_song_changed),
        .note_done(note_done),
        .song_length(song_length),
        .playback_mode(playback_mode),
        .note_index(note_index),
        .playing(playing),
        .paused(paused),
        .stopped(stopped)
    );

    song_rom u_song_rom (
        .song_select(selected_song),
        .note_index(note_index),
        .note_word(note_word),
        .song_length(song_length),
        .total_duration_units(total_duration_units),
        .default_bpm(default_bpm),
        .beats_per_bar(beats_per_bar),
        .first_beat_in_bar(first_beat_in_bar)
    );

    assign duration_units = note_word[5:0];
    assign song_wrap = note_done &&
                       ((song_length == 0) || (note_index >= song_length - 1'b1));
    assign auto_next_song = song_wrap && (playback_mode == 2'd2);
    assign playback_timing_clear =
        stopped || stop_pressed || song_changed || auto_song_changed || song_wrap;

    pitch_processor u_pitch_processor (
        .transpose_semitones(transpose_semitones),
        .note_word(note_word),
        .semitone_pitch(semitone_pitch),
        .display_note_name(display_note_name),
        .display_accidental(display_accidental),
        .display_octave(display_octave),
        .is_rest(note_is_rest)
    );

    beat_controller #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .NOTE_GAP_MS(NOTE_GAP_MS)
    ) u_beat_controller (
        .clk(clk),
        .rst_n(rst_n),
        .enable(playing),
        .clear(playback_timing_clear),
        .bpm(current_bpm),
        .duration_units(duration_units),
        .note_done(note_done),
        .tone_enable(tone_enable),
        .unit_pulse(unit_pulse),
        .beat_pulse(beat_pulse)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            elapsed_units      <= 16'd0;
            elapsed_seconds    <= 16'd0;
            second_tick_count  <= 32'd0;
            beat_in_bar        <= 2'd0;
            current_bar_number <= 10'd1;
        end else if (playback_timing_clear) begin
            elapsed_units      <= 16'd0;
            elapsed_seconds    <= 16'd0;
            second_tick_count  <= 32'd0;
            beat_in_bar        <= safe_first_beat_in_bar;
            current_bar_number <= 10'd1;
        end else if (playing) begin
            if (unit_pulse && (elapsed_units < total_duration_units))
                elapsed_units <= elapsed_units + 1'b1;

            if (beat_pulse) begin
                if ({1'b0, beat_in_bar} >= (safe_beats_per_bar - 1'b1)) begin
                    beat_in_bar <= 2'd0;
                    if (current_bar_number < 10'd999)
                        current_bar_number <= current_bar_number + 1'b1;
                end else begin
                    beat_in_bar <= beat_in_bar + 1'b1;
                end
            end

            if ((SECOND_TICKS <= 1) || (second_tick_count >= SECOND_TICKS - 1)) begin
                second_tick_count <= 32'd0;
                elapsed_seconds <= elapsed_seconds + 1'b1;
            end else begin
                second_tick_count <= second_tick_count + 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            playback_display_mode <= DISPLAY_ELAPSED;
        end else if (display_mode_pressed) begin
            case (playback_display_mode)
                DISPLAY_ELAPSED: playback_display_mode <= DISPLAY_REMAIN;
                DISPLAY_REMAIN:  playback_display_mode <= DISPLAY_BAR;
                default:         playback_display_mode <= DISPLAY_ELAPSED;
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            self_test_active <= 1'b0;
        end else if (self_test_toggle_pulse) begin
            self_test_active <= ~self_test_active;
        end
    end

    tone_generator #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) u_tone_generator (
        .clk(clk),
        .rst_n(rst_n),
        .enable(tone_enable),
        .is_rest(note_is_rest),
        .semitone_pitch(semitone_pitch),
        .volume_level(volume_level),
        .beep(music_beep)
    );

    led_panel_controller #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) u_led_panel_controller (
        .clk(clk),
        .rst_n(rst_n),
        .is_rest(note_is_rest),
        .display_note_name(display_note_name),
        .display_accidental(display_accidental),
        .display_octave(display_octave),
        .beats_per_bar(safe_beats_per_bar),
        .beat_in_bar(beat_in_bar),
        .elapsed_units(elapsed_units),
        .total_duration_units(total_duration_units),
        .row0(led_row0),
        .row1(led_row1),
        .row2(led_row2),
        .row3(led_row3)
    );

    board_led_mapper u_board_led_mapper (
        .row0(led_row0),
        .row1(led_row1),
        .row2(led_row2),
        .row3(led_row3),
        .led(music_led)
    );

    self_test_controller #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) u_self_test_controller (
        .clk(clk),
        .rst_n(rst_n),
        .led(self_test_led),
        .glyphs(self_test_glyphs),
        .decimal_points(self_test_decimal_points),
        .blank(self_test_blank),
        .beep(self_test_beep)
    );

    sevenseg_ui_formatter #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) u_sevenseg_formatter (
        .clk(clk),
        .rst_n(rst_n),
        .edit_mode(edit_mode),
        .selected_song(selected_song_index),
        .transpose_semitones(transpose_semitones),
        .bpm(current_bpm),
        .volume_level(volume_level),
        .playback_mode(playback_mode),
        .playback_display_mode(playback_display_mode),
        .elapsed_seconds(elapsed_seconds),
        .remaining_seconds(remaining_seconds),
        .bar_number(current_bar_number),
        .beat_number(current_beat_number),
        .paused(paused),
        .glyphs(sevenseg_glyphs),
        .decimal_points(sevenseg_decimal_points),
        .blank(sevenseg_blank)
    );

    sevenseg_scan_controller #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) u_sevenseg_scan (
        .clk(clk),
        .rst_n(rst_n),
        .glyphs(active_sevenseg_glyphs),
        .decimal_points(active_sevenseg_decimal_points),
        .blank(active_sevenseg_blank),
        .seg(seg),
        .seg_cs(seg_cs)
    );

endmodule
