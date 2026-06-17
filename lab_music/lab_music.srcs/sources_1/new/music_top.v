`timescale 1ns / 1ps

module music_top #(
    parameter integer CLK_FREQ_HZ    = 200_000_000,
    parameter integer BEAT_MS        = 500,
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
    output wire [31:0] led
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
    wire [7:0] note_index;
    wire [15:0] note_word;
    wire note_is_rest;
    wire [2:0] note_name;
    wire [1:0] note_accidental;
    wire [3:0] note_octave;
    wire [5:0] duration_16th;
    wire [5:0] duration_beats_raw;
    wire [4:0] note_code;
    wire [3:0] note_duration;
    wire [7:0] song_length;
    wire [15:0] total_duration_16th;
    wire [7:0] default_bpm;
    wire [2:0] key_tonic;
    wire [1:0] key_accidental;
    wire key_mode;
    wire note_done;
    wire tone_enable;
    wire playing;
    wire paused;
    wire stopped;
    wire [2:0] volume_level;
    wire [7:0] status_led;
    wire [7:0] led_row3;
    reg [4:0] decoded_note_code;

    localparam [2:0] NOTE_NAME_C = 3'd0;
    localparam [2:0] NOTE_NAME_D = 3'd1;
    localparam [2:0] NOTE_NAME_E = 3'd2;
    localparam [2:0] NOTE_NAME_F = 3'd3;
    localparam [2:0] NOTE_NAME_G = 3'd4;
    localparam [2:0] NOTE_NAME_A = 3'd5;

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

    volume_controller u_volume_controller (
        .clk(clk),
        .rst_n(rst_n),
        .volume_down_pressed(volume_down_pressed),
        .volume_up_pressed(volume_up_pressed),
        .volume_level(volume_level)
    );

    player_controller u_player (
        .clk(clk),
        .rst_n(rst_n),
        .play_pause_pressed(play_pressed),
        .stop_pressed(stop_pressed),
        .next_pressed(next_pressed),
        .note_done(note_done),
        .song_length(song_length),
        .selected_song(selected_song),
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

    assign note_is_rest = note_word[15];
    assign note_name = note_word[14:12];
    assign note_accidental = note_word[11:10];
    assign note_octave = note_word[9:6];
    assign duration_16th = note_word[5:0];
    assign duration_beats_raw = (duration_16th + 6'd3) >> 2;
    assign note_duration = (duration_beats_raw == 0) ? 4'd1 : duration_beats_raw[3:0];
    assign note_code = note_is_rest ? 5'd0 : decoded_note_code;

    always @(*) begin
        case (note_name)
            NOTE_NAME_C: decoded_note_code = 5'd1;
            NOTE_NAME_D: decoded_note_code = 5'd2;
            NOTE_NAME_E: decoded_note_code = 5'd3;
            NOTE_NAME_F: decoded_note_code = 5'd4;
            NOTE_NAME_G: decoded_note_code = 5'd5;
            NOTE_NAME_A: decoded_note_code = 5'd6;
            default:     decoded_note_code = 5'd0;
        endcase
    end

    beat_controller #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BEAT_MS(BEAT_MS),
        .NOTE_GAP_MS(NOTE_GAP_MS)
    ) u_beat_controller (
        .clk(clk),
        .rst_n(rst_n),
        .enable(playing),
        .clear(stopped || stop_pressed || next_pressed),
        .duration_beats(note_duration),
        .note_done(note_done),
        .tone_enable(tone_enable)
    );

    tone_generator #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) u_tone_generator (
        .clk(clk),
        .rst_n(rst_n),
        .enable(tone_enable),
        .note_code(note_code),
        .volume_level(volume_level),
        .beep(beep)
    );

    // Temporary status display on the bottom physical LED row.
    assign status_led[0] = playing;
    assign status_led[1] = paused;
    assign status_led[2] = stopped;
    assign status_led[3] = selected_song[0];
    assign status_led[4] = (volume_level >= 3'd1);
    assign status_led[5] = (volume_level >= 3'd2);
    assign status_led[6] = (volume_level >= 3'd3);
    assign status_led[7] = (volume_level >= 3'd4);
    assign led_row3 = {
        status_led[0],
        status_led[1],
        status_led[2],
        status_led[3],
        status_led[4],
        status_led[5],
        status_led[6],
        status_led[7]
    };

    board_led_mapper u_board_led_mapper (
        .row0(8'b0000_0000),
        .row1(8'b0000_0000),
        .row2(8'b0000_0000),
        .row3(led_row3),
        .led(led)
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
