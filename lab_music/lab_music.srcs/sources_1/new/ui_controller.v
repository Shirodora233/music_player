`timescale 1ns / 1ps

module ui_controller #(
    parameter integer CLK_FREQ_HZ = 200_000_000,
    parameter integer SONG_COUNT  = 2
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              next_pressed,
    input  wire              value_down_pressed,
    input  wire              value_up_pressed,
    input  wire              auto_next_song,
    input  wire [7:0]        default_bpm,
    output reg  [1:0]        selected_song,
    output reg signed [5:0]  transpose_semitones,
    output reg  [7:0]        current_bpm,
    output reg  [2:0]        volume_level,
    output reg  [1:0]        playback_mode,
    output reg  [2:0]        edit_mode,
    output reg               song_changed,
    output reg               auto_song_changed
);

    localparam [2:0] EDIT_SONG      = 3'd0;
    localparam [2:0] EDIT_TRANSPOSE = 3'd1;
    localparam [2:0] EDIT_BPM       = 3'd2;
    localparam [2:0] EDIT_VOLUME    = 3'd3;
    localparam [2:0] EDIT_PLAY_MODE = 3'd4;

    localparam [1:0] PLAY_MODE_STOP = 2'd0;
    localparam [1:0] PLAY_MODE_ONE  = 2'd1;
    localparam [1:0] PLAY_MODE_ALL  = 2'd2;

    localparam signed [5:0] TRANSPOSE_MIN = -6'sd12;
    localparam signed [5:0] TRANSPOSE_MAX =  6'sd12;
    localparam [7:0] BPM_MIN = 8'd30;
    localparam [7:0] BPM_MAX = 8'd250;
    localparam [2:0] VOLUME_MIN = 3'd0;
    localparam [2:0] VOLUME_MAX = 3'd7;
    localparam [31:0] RETURN_TIMEOUT_TICKS = CLK_FREQ_HZ * 5;

    reg [31:0] inactivity_count;
    reg load_default_bpm_pending;
    wire edit_event = next_pressed || value_down_pressed || value_up_pressed;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            selected_song       <= 2'd0;
            transpose_semitones <= 6'sd0;
            current_bpm         <= 8'd120;
            volume_level        <= VOLUME_MAX;
            playback_mode       <= PLAY_MODE_STOP;
            edit_mode           <= EDIT_SONG;
            inactivity_count    <= 32'd0;
            load_default_bpm_pending <= 1'b1;
            song_changed        <= 1'b0;
            auto_song_changed   <= 1'b0;
        end else begin
            song_changed <= 1'b0;
            auto_song_changed <= 1'b0;

            if (load_default_bpm_pending) begin
                current_bpm <= default_bpm;
                load_default_bpm_pending <= 1'b0;
            end

            if (auto_next_song && (SONG_COUNT > 1)) begin
                if (selected_song >= SONG_COUNT - 1)
                    selected_song <= 2'd0;
                else
                    selected_song <= selected_song + 1'b1;
                auto_song_changed <= 1'b1;
                load_default_bpm_pending <= 1'b1;
            end

            if (edit_event) begin
                inactivity_count <= 32'd0;
            end else if (edit_mode != EDIT_SONG) begin
                if ((RETURN_TIMEOUT_TICKS <= 1) ||
                    (inactivity_count >= RETURN_TIMEOUT_TICKS - 1)) begin
                    edit_mode <= EDIT_SONG;
                    inactivity_count <= 32'd0;
                end else begin
                    inactivity_count <= inactivity_count + 1'b1;
                end
            end

            if (next_pressed) begin
                case (edit_mode)
                    EDIT_SONG:      edit_mode <= EDIT_TRANSPOSE;
                    EDIT_TRANSPOSE: edit_mode <= EDIT_BPM;
                    EDIT_BPM:       edit_mode <= EDIT_VOLUME;
                    EDIT_VOLUME:    edit_mode <= EDIT_PLAY_MODE;
                    default:        edit_mode <= EDIT_SONG;
                endcase
            end else if (value_up_pressed && !value_down_pressed) begin
                case (edit_mode)
                    EDIT_SONG: begin
                        if (SONG_COUNT > 1) begin
                            if (selected_song >= SONG_COUNT - 1)
                                selected_song <= 2'd0;
                            else
                                selected_song <= selected_song + 1'b1;
                            song_changed <= 1'b1;
                            load_default_bpm_pending <= 1'b1;
                        end
                    end
                    EDIT_TRANSPOSE: begin
                        if (transpose_semitones < TRANSPOSE_MAX)
                            transpose_semitones <= transpose_semitones + 1'b1;
                    end
                    EDIT_BPM: begin
                        if (current_bpm < BPM_MAX)
                            current_bpm <= current_bpm + 1'b1;
                    end
                    EDIT_VOLUME: begin
                        if (volume_level < VOLUME_MAX)
                            volume_level <= volume_level + 1'b1;
                    end
                    EDIT_PLAY_MODE: begin
                        if (playback_mode >= PLAY_MODE_ALL)
                            playback_mode <= PLAY_MODE_STOP;
                        else
                            playback_mode <= playback_mode + 1'b1;
                    end
                    default: begin
                    end
                endcase
            end else if (value_down_pressed && !value_up_pressed) begin
                case (edit_mode)
                    EDIT_SONG: begin
                        if (SONG_COUNT > 1) begin
                            if (selected_song == 0)
                                selected_song <= SONG_COUNT - 1;
                            else
                                selected_song <= selected_song - 1'b1;
                            song_changed <= 1'b1;
                            load_default_bpm_pending <= 1'b1;
                        end
                    end
                    EDIT_TRANSPOSE: begin
                        if (transpose_semitones > TRANSPOSE_MIN)
                            transpose_semitones <= transpose_semitones - 1'b1;
                    end
                    EDIT_BPM: begin
                        if (current_bpm > BPM_MIN)
                            current_bpm <= current_bpm - 1'b1;
                    end
                    EDIT_VOLUME: begin
                        if (volume_level > VOLUME_MIN)
                            volume_level <= volume_level - 1'b1;
                    end
                    EDIT_PLAY_MODE: begin
                        if (playback_mode == PLAY_MODE_STOP)
                            playback_mode <= PLAY_MODE_ALL;
                        else
                            playback_mode <= playback_mode - 1'b1;
                    end
                    default: begin
                    end
                endcase
            end
        end
    end

endmodule
