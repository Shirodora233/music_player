`timescale 1ns / 1ps

module pitch_processor (
    input  wire signed [5:0] transpose_semitones,
    input  wire [15:0]       note_word,
    output reg  [7:0]        semitone_pitch,
    output reg  [2:0]        display_note_name,
    output reg  [1:0]        display_accidental,
    output reg  [3:0]        display_octave,
    output wire              is_rest
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

    wire [2:0] source_note_name = note_word[14:12];
    wire [1:0] source_accidental = note_word[11:10];
    wire [3:0] source_octave = note_word[9:6];

    integer source_midi;
    integer target_midi;
    integer source_diatonic;
    integer target_diatonic;
    integer target_note_name_int;
    integer target_octave_int;
    integer target_natural_midi;
    integer target_accidental_offset;

    assign is_rest = note_word[15];

    function integer natural_pc;
        input [2:0] note_name;
        begin
            case (note_name)
                N_C: natural_pc = 0;
                N_D: natural_pc = 2;
                N_E: natural_pc = 4;
                N_F: natural_pc = 5;
                N_G: natural_pc = 7;
                N_A: natural_pc = 9;
                N_B: natural_pc = 11;
                default: natural_pc = 0;
            endcase
        end
    endfunction

    function integer accidental_offset;
        input [1:0] accidental;
        begin
            case (accidental)
                ACC_FLAT:    accidental_offset = -1;
                ACC_SHARP:   accidental_offset = 1;
                default:     accidental_offset = 0;
            endcase
        end
    endfunction

    function integer interval_degree_delta;
        input signed [5:0] semitones;
        integer abs_semitones;
        integer delta;
        begin
            abs_semitones = (semitones < 0) ? -semitones : semitones;
            case (abs_semitones)
                0:  delta = 0;
                1:  delta = 1;
                2:  delta = 1;
                3:  delta = 2;
                4:  delta = 2;
                5:  delta = 3;
                6:  delta = 3; // Augmented fourth by default.
                7:  delta = 4;
                8:  delta = 5;
                9:  delta = 5;
                10: delta = 6;
                11: delta = 6;
                12: delta = 7;
                default: delta = 0;
            endcase

            interval_degree_delta = (semitones < 0) ? -delta : delta;
        end
    endfunction

    always @(*) begin
        semitone_pitch      = 8'd0;
        display_note_name   = N_C;
        display_accidental  = ACC_NATURAL;
        display_octave      = 4'd0;

        if (!is_rest) begin
            source_midi =
                ((source_octave + 1) * 12) +
                natural_pc(source_note_name) +
                accidental_offset(source_accidental);
            target_midi = source_midi + transpose_semitones;

            if (target_midi < 0)
                target_midi = 0;
            else if (target_midi > 127)
                target_midi = 127;

            source_diatonic = (source_octave * 7) + source_note_name;
            target_diatonic = source_diatonic +
                              interval_degree_delta(transpose_semitones);

            if (target_diatonic < 0)
                target_diatonic = 0;
            else if (target_diatonic > ((8 * 7) + 6))
                target_diatonic = (8 * 7) + 6;

            target_note_name_int = target_diatonic % 7;
            target_octave_int = target_diatonic / 7;
            target_natural_midi =
                ((target_octave_int + 1) * 12) +
                natural_pc(target_note_name_int[2:0]);
            target_accidental_offset = target_midi - target_natural_midi;

            semitone_pitch = target_midi[7:0];
            display_note_name = target_note_name_int[2:0];
            display_octave = target_octave_int[3:0];

            if (target_accidental_offset < 0)
                display_accidental = ACC_FLAT;
            else if (target_accidental_offset > 0)
                display_accidental = ACC_SHARP;
            else
                display_accidental = ACC_NATURAL;
        end
    end

endmodule
