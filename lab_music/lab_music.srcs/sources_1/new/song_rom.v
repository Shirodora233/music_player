`timescale 1ns / 1ps

module song_rom (
    input  wire [0:0] song_select,
    input  wire [7:0] note_index,
    output reg  [15:0] note_word,
    output reg  [7:0] song_length,
    output reg  [15:0] total_duration_16th,
    output reg  [7:0] default_bpm,
    output reg  [2:0] key_tonic,
    output reg  [1:0] key_accidental,
    output reg        key_mode,
    output reg  [2:0] beats_per_bar,
    output reg  [1:0] first_beat_in_bar
);

    localparam [2:0] N_C = 3'd0;
    localparam [2:0] N_D = 3'd1;
    localparam [2:0] N_E = 3'd2;
    localparam [2:0] N_F = 3'd3;
    localparam [2:0] N_G = 3'd4;
    localparam [2:0] N_A = 3'd5;
    localparam [2:0] N_B = 3'd6;

    localparam [1:0] ACC_FLAT    = 2'd0;
    localparam [1:0] ACC_NATURAL = 2'd1;
    localparam [1:0] ACC_SHARP   = 2'd2;

    localparam       MODE_MAJOR = 1'b0;

    localparam [5:0] DUR_QUARTER = 6'd4;
    localparam [5:0] DUR_HALF    = 6'd8;

    function [15:0] note;
        input [2:0] name;
        input [1:0] accidental;
        input [3:0] octave;
        input [5:0] duration_16th;
        begin
            note = {1'b0, name, accidental, octave, duration_16th};
        end
    endfunction

    function [15:0] rest;
        input [5:0] duration_16th;
        begin
            rest = {1'b1, N_C, ACC_NATURAL, 4'd0, duration_16th};
        end
    endfunction

    always @(*) begin
        note_word           = rest(DUR_QUARTER);
        song_length         = 8'd0;
        total_duration_16th = 16'd0;
        default_bpm         = 8'd120;
        key_tonic           = N_C;
        key_accidental      = ACC_NATURAL;
        key_mode            = MODE_MAJOR;
        beats_per_bar       = 3'd4;
        first_beat_in_bar   = 2'd0;

        if (song_select == 1'b0) begin
            // Song 0: Twinkle Twinkle Little Star, 4/4 time.
            song_length         = 8'd42;
            total_duration_16th = 16'd192;
            beats_per_bar       = 3'd4;
            first_beat_in_bar   = 2'd0;
            case (note_index)
                8'd0,  8'd1:  note_word = note(N_C, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd2,  8'd3:  note_word = note(N_G, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd4,  8'd5:  note_word = note(N_A, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd6:         note_word = note(N_G, ACC_NATURAL, 4'd4, DUR_HALF);
                8'd7,  8'd8:  note_word = note(N_F, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd9,  8'd10: note_word = note(N_E, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd11, 8'd12: note_word = note(N_D, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd13:        note_word = note(N_C, ACC_NATURAL, 4'd4, DUR_HALF);
                8'd14, 8'd15: note_word = note(N_G, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd16, 8'd17: note_word = note(N_F, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd18, 8'd19: note_word = note(N_E, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd20:        note_word = note(N_D, ACC_NATURAL, 4'd4, DUR_HALF);
                8'd21, 8'd22: note_word = note(N_G, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd23, 8'd24: note_word = note(N_F, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd25, 8'd26: note_word = note(N_E, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd27:        note_word = note(N_D, ACC_NATURAL, 4'd4, DUR_HALF);
                8'd28, 8'd29: note_word = note(N_C, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd30, 8'd31: note_word = note(N_G, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd32, 8'd33: note_word = note(N_A, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd34:        note_word = note(N_G, ACC_NATURAL, 4'd4, DUR_HALF);
                8'd35, 8'd36: note_word = note(N_F, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd37, 8'd38: note_word = note(N_E, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd39, 8'd40: note_word = note(N_D, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd41:        note_word = note(N_C, ACC_NATURAL, 4'd4, DUR_HALF);
                default:      note_word = rest(DUR_QUARTER);
            endcase
        end else begin
            // Song 1: Two Tigers, 4/4 time.
            song_length         = 8'd32;
            total_duration_16th = 16'd144;
            beats_per_bar       = 3'd4;
            first_beat_in_bar   = 2'd0;
            case (note_index)
                8'd0,  8'd4:  note_word = note(N_C, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd1,  8'd5:  note_word = note(N_D, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd2,  8'd6:  note_word = note(N_E, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd3,  8'd7:  note_word = note(N_C, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd8,  8'd11: note_word = note(N_E, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd9,  8'd12: note_word = note(N_F, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd10, 8'd13: note_word = note(N_G, ACC_NATURAL, 4'd4, DUR_HALF);
                8'd14, 8'd20: note_word = note(N_G, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd15, 8'd21: note_word = note(N_A, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd16, 8'd22: note_word = note(N_G, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd17, 8'd23: note_word = note(N_F, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd18, 8'd24: note_word = note(N_E, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd19, 8'd25: note_word = note(N_C, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd26, 8'd29: note_word = note(N_C, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd27, 8'd30: note_word = note(N_G, ACC_NATURAL, 4'd4, DUR_QUARTER);
                8'd28, 8'd31: note_word = note(N_C, ACC_NATURAL, 4'd4, DUR_HALF);
                default:      note_word = rest(DUR_QUARTER);
            endcase
        end
    end

endmodule
