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
    input  wire [7:0]        default_bpm,
    output reg  [0:0]        selected_song,
    output reg signed [5:0]  transpose_semitones,
    output reg  [7:0]        current_bpm,
    output reg  [1:0]        edit_mode,
    output reg               song_changed
);

    localparam [1:0] EDIT_SONG      = 2'd0;
    localparam [1:0] EDIT_TRANSPOSE = 2'd1;
    localparam [1:0] EDIT_BPM       = 2'd2;

    localparam signed [5:0] TRANSPOSE_MIN = -6'sd12;
    localparam signed [5:0] TRANSPOSE_MAX =  6'sd12;
    localparam [7:0] BPM_MIN = 8'd30;
    localparam [7:0] BPM_MAX = 8'd250;
    localparam [31:0] RETURN_TIMEOUT_TICKS = CLK_FREQ_HZ * 5;

    reg [31:0] inactivity_count;
    wire edit_event = next_pressed || value_down_pressed || value_up_pressed;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            selected_song       <= 1'b0;
            transpose_semitones <= 6'sd0;
            current_bpm         <= 8'd120;
            edit_mode           <= EDIT_SONG;
            inactivity_count    <= 32'd0;
            song_changed        <= 1'b0;
        end else begin
            song_changed <= 1'b0;

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
                    default:        edit_mode <= EDIT_SONG;
                endcase
            end else if (value_up_pressed && !value_down_pressed) begin
                case (edit_mode)
                    EDIT_SONG: begin
                        if (SONG_COUNT > 1) begin
                            if (selected_song >= SONG_COUNT - 1)
                                selected_song <= 1'b0;
                            else
                                selected_song <= selected_song + 1'b1;
                            song_changed <= 1'b1;
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
                    default: begin
                    end
                endcase
            end
        end
    end

endmodule
