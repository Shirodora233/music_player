`timescale 1ns / 1ps

module player_controller (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       play_pause_pressed,
    input  wire       stop_pressed,
    input  wire       next_pressed,
    input  wire       note_done,
    input  wire [5:0] song_length,
    output reg  [0:0] selected_song,
    output reg  [5:0] note_index,
    output wire       playing,
    output wire       paused,
    output wire       stopped
);

    localparam [1:0] STATE_STOPPED = 2'd0;
    localparam [1:0] STATE_PLAYING = 2'd1;
    localparam [1:0] STATE_PAUSED  = 2'd2;

    reg [1:0] state;

    assign stopped = (state == STATE_STOPPED);
    assign playing = (state == STATE_PLAYING);
    assign paused  = (state == STATE_PAUSED);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= STATE_STOPPED;
            selected_song <= 1'b0;
            note_index    <= 6'd0;
        end else if (stop_pressed) begin
            state      <= STATE_STOPPED;
            note_index <= 6'd0;
        end else if (next_pressed) begin
            selected_song <= ~selected_song;
            note_index    <= 6'd0;
        end else if (play_pause_pressed) begin
            case (state)
                STATE_PLAYING: state <= STATE_PAUSED;
                STATE_PAUSED:  state <= STATE_PLAYING;
                default:       state <= STATE_PLAYING;
            endcase
        end else if (playing && note_done) begin
            if ((song_length == 0) || (note_index >= song_length - 1'b1))
                note_index <= 6'd0;
            else
                note_index <= note_index + 1'b1;
        end
    end

endmodule
