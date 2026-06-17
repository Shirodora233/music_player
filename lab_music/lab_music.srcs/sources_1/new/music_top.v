`timescale 1ns / 1ps

module music_top #(
    parameter integer CLK_FREQ_HZ    = 200_000_000,
    parameter integer NOTE_GAP_MS    = 20,
    parameter integer DEBOUNCE_MS    = 20,
    parameter integer KEY_ACTIVE_LOW = 1
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       key_play_pause,
    input  wire       key_stop,
    input  wire       key_next,
    input  wire       key_volume_down,
    input  wire       key_volume_up,
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
    wire play_pressed;
    wire stop_pressed;
    wire next_pressed;
    wire volume_down_pressed;
    wire volume_up_pressed;

    wire [0:0] selected_song;
    wire song_changed;
    wire [7:0] note_index;
    wire [15:0] note_word;
    wire note_is_rest;
    wire [5:0] duration_16th;
    wire signed [5:0] transpose_semitones;
    wire [7:0] current_bpm;
    wire [7:0] semitone_pitch;
    wire [2:0] display_note_name;
    wire [1:0] display_accidental;
    wire [3:0] display_octave;
    wire [7:0] song_length;
    wire [15:0] total_duration_16th;
    wire [7:0] default_bpm;
    wire [2:0] key_tonic;
    wire [1:0] key_accidental;
    wire key_mode;
    wire note_done;
    wire sixteenth_pulse;
    wire beat_pulse;
    wire tone_enable;
    wire song_wrap;
    wire playback_timing_clear;
    wire playing;
    wire paused;
    wire stopped;
    wire [1:0] edit_mode;
    wire [2:0] volume_level;
    wire [7:0] led_row0;
    wire [7:0] led_row1;
    wire [7:0] led_row2;
    wire [7:0] led_row3;
    wire [39:0] sevenseg_test_glyphs;
    reg [15:0] elapsed_16th_units;
    reg [15:0] elapsed_seconds;
    reg [31:0] second_tick_count;

    localparam [31:0] SECOND_TICKS = CLK_FREQ_HZ;

    assign volume_level = 3'd4;
    assign sevenseg_test_glyphs = {5'd1, 5'd2, 5'd3, 5'd4, 5'd5, 5'd6, 5'd7, 5'd8};

    assign play_key_level = KEY_ACTIVE_LOW ? ~key_play_pause : key_play_pause;
    assign stop_key_level = KEY_ACTIVE_LOW ? ~key_stop       : key_stop;
    assign next_key_level = KEY_ACTIVE_LOW ? ~key_next       : key_next;
    assign volume_down_key_level = KEY_ACTIVE_LOW ? ~key_volume_down : key_volume_down;
    assign volume_up_key_level   = KEY_ACTIVE_LOW ? ~key_volume_up   : key_volume_up;

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
        .key_state(),
        .key_pressed(volume_down_pressed)
    );

    button_debounce #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u_debounce_volume_up (
        .clk(clk),
        .rst_n(rst_n),
        .key_in(volume_up_key_level),
        .key_state(),
        .key_pressed(volume_up_pressed)
    );

    ui_controller #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .SONG_COUNT(2)
    ) u_ui_controller (
        .clk(clk),
        .rst_n(rst_n),
        .next_pressed(next_pressed),
        .value_down_pressed(volume_down_pressed),
        .value_up_pressed(volume_up_pressed),
        .default_bpm(default_bpm),
        .selected_song(selected_song),
        .transpose_semitones(transpose_semitones),
        .current_bpm(current_bpm),
        .edit_mode(edit_mode),
        .song_changed(song_changed)
    );

    player_controller u_player (
        .clk(clk),
        .rst_n(rst_n),
        .play_pause_pressed(play_pressed),
        .stop_pressed(stop_pressed),
        .song_changed(song_changed),
        .note_done(note_done),
        .song_length(song_length),
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
        .total_duration_16th(total_duration_16th),
        .default_bpm(default_bpm),
        .key_tonic(key_tonic),
        .key_accidental(key_accidental),
        .key_mode(key_mode)
    );

    assign duration_16th = note_word[5:0];
    assign song_wrap = note_done &&
                       ((song_length == 0) || (note_index >= song_length - 1'b1));
    assign playback_timing_clear = stopped || stop_pressed || song_changed || song_wrap;

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
        .duration_16th(duration_16th),
        .note_done(note_done),
        .tone_enable(tone_enable),
        .sixteenth_pulse(sixteenth_pulse),
        .beat_pulse(beat_pulse)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            elapsed_16th_units <= 16'd0;
            elapsed_seconds    <= 16'd0;
            second_tick_count  <= 32'd0;
        end else if (playback_timing_clear) begin
            elapsed_16th_units <= 16'd0;
            elapsed_seconds    <= 16'd0;
            second_tick_count  <= 32'd0;
        end else if (playing) begin
            if (sixteenth_pulse && (elapsed_16th_units < total_duration_16th))
                elapsed_16th_units <= elapsed_16th_units + 1'b1;

            if ((SECOND_TICKS <= 1) || (second_tick_count >= SECOND_TICKS - 1)) begin
                second_tick_count <= 32'd0;
                elapsed_seconds <= elapsed_seconds + 1'b1;
            end else begin
                second_tick_count <= second_tick_count + 1'b1;
            end
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
        .beep(beep)
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
        .beat_pulse(beat_pulse),
        .elapsed_16th_units(elapsed_16th_units),
        .total_duration_16th(total_duration_16th),
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
        .led(led)
    );

    sevenseg_scan_controller #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) u_sevenseg_scan (
        .clk(clk),
        .rst_n(rst_n),
        .glyphs(sevenseg_test_glyphs),
        .decimal_points(8'b0000_0000),
        .blank(8'b0000_0000),
        .seg(seg),
        .seg_cs(seg_cs)
    );

endmodule

module volume_controller (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       volume_down_pressed,
    input  wire       volume_up_pressed,
    output reg  [2:0] volume_level
);

    localparam [2:0] VOLUME_MIN = 3'd0;
    localparam [2:0] VOLUME_MAX = 3'd4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            volume_level <= VOLUME_MAX;
        end else if (volume_down_pressed && !volume_up_pressed) begin
            if (volume_level > VOLUME_MIN)
                volume_level <= volume_level - 1'b1;
        end else if (volume_up_pressed && !volume_down_pressed) begin
            if (volume_level < VOLUME_MAX)
                volume_level <= volume_level + 1'b1;
        end
    end

endmodule
