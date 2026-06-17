`timescale 1ns / 1ps

module sevenseg_ui_formatter #(
    parameter integer CLK_FREQ_HZ = 200_000_000
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire [1:0]        edit_mode,
    input  wire [7:0]        selected_song,
    input  wire signed [5:0] transpose_semitones,
    input  wire [7:0]        bpm,
    input  wire [15:0]       elapsed_seconds,
    input  wire              paused,
    output reg  [39:0]       glyphs,
    output reg  [7:0]        decimal_points,
    output reg  [7:0]        blank
);

    localparam [1:0] EDIT_SONG      = 2'd0;
    localparam [1:0] EDIT_TRANSPOSE = 2'd1;
    localparam [1:0] EDIT_BPM       = 2'd2;

    localparam [4:0] GLYPH_0     = 5'd0;
    localparam [4:0] GLYPH_1     = 5'd1;
    localparam [4:0] GLYPH_2     = 5'd2;
    localparam [4:0] GLYPH_3     = 5'd3;
    localparam [4:0] GLYPH_4     = 5'd4;
    localparam [4:0] GLYPH_5     = 5'd5;
    localparam [4:0] GLYPH_6     = 5'd6;
    localparam [4:0] GLYPH_7     = 5'd7;
    localparam [4:0] GLYPH_8     = 5'd8;
    localparam [4:0] GLYPH_9     = 5'd9;
    localparam [4:0] GLYPH_BLANK = 5'd10;
    localparam [4:0] GLYPH_MINUS = 5'd11;
    localparam [4:0] GLYPH_S     = 5'd12;
    localparam [4:0] GLYPH_T     = 5'd13;
    localparam [4:0] GLYPH_B     = 5'd14;
    localparam [4:0] GLYPH_PLUS  = 5'd15;

    localparam integer BLINK_TICKS_RAW = CLK_FREQ_HZ / 2;
    localparam integer BLINK_TICKS     = (BLINK_TICKS_RAW < 1) ? 1 : BLINK_TICKS_RAW;

    reg [31:0] blink_counter;
    reg        blink_visible;
    reg [4:0]  glyph_d0;
    reg [4:0]  glyph_d1;
    reg [4:0]  glyph_d2;
    reg [4:0]  glyph_d3;
    reg [4:0]  glyph_d4;
    reg [4:0]  glyph_d5;
    reg [4:0]  glyph_d6;
    reg [4:0]  glyph_d7;
    reg [7:0]  song_display;
    reg [5:0]  transpose_abs;
    reg [7:0]  display_minutes;
    reg [5:0]  display_seconds;
    reg [15:0] clamped_elapsed_seconds;

    function [4:0] digit_to_glyph;
        input [3:0] digit;
        begin
            case (digit)
                4'd0: digit_to_glyph = GLYPH_0;
                4'd1: digit_to_glyph = GLYPH_1;
                4'd2: digit_to_glyph = GLYPH_2;
                4'd3: digit_to_glyph = GLYPH_3;
                4'd4: digit_to_glyph = GLYPH_4;
                4'd5: digit_to_glyph = GLYPH_5;
                4'd6: digit_to_glyph = GLYPH_6;
                4'd7: digit_to_glyph = GLYPH_7;
                4'd8: digit_to_glyph = GLYPH_8;
                4'd9: digit_to_glyph = GLYPH_9;
                default: digit_to_glyph = GLYPH_BLANK;
            endcase
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            blink_counter <= 32'd0;
            blink_visible <= 1'b1;
        end else if (!paused) begin
            blink_counter <= 32'd0;
            blink_visible <= 1'b1;
        end else if (blink_counter >= BLINK_TICKS - 1) begin
            blink_counter <= 32'd0;
            blink_visible <= ~blink_visible;
        end else begin
            blink_counter <= blink_counter + 1'b1;
        end
    end

    always @* begin
        song_display = selected_song + 1'b1;

        if (transpose_semitones < 0)
            transpose_abs = -transpose_semitones;
        else
            transpose_abs = transpose_semitones;

        if (elapsed_seconds > 16'd5999)
            clamped_elapsed_seconds = 16'd5999;
        else
            clamped_elapsed_seconds = elapsed_seconds;

        display_minutes = clamped_elapsed_seconds / 16'd60;
        display_seconds = clamped_elapsed_seconds % 16'd60;

        glyph_d3 = digit_to_glyph(display_minutes / 8'd10);
        glyph_d2 = digit_to_glyph(display_minutes % 8'd10);
        glyph_d1 = digit_to_glyph(display_seconds / 6'd10);
        glyph_d0 = digit_to_glyph(display_seconds % 6'd10);

        case (edit_mode)
            EDIT_TRANSPOSE: begin
                glyph_d7 = GLYPH_T;
                glyph_d6 = (transpose_semitones < 0) ? GLYPH_MINUS : GLYPH_PLUS;
                glyph_d5 = digit_to_glyph(transpose_abs / 6'd10);
                glyph_d4 = digit_to_glyph(transpose_abs % 6'd10);
            end
            EDIT_BPM: begin
                glyph_d7 = GLYPH_B;
                glyph_d6 = digit_to_glyph(bpm / 8'd100);
                glyph_d5 = digit_to_glyph((bpm / 8'd10) % 8'd10);
                glyph_d4 = digit_to_glyph(bpm % 8'd10);
            end
            EDIT_SONG: begin
                glyph_d7 = GLYPH_S;
                glyph_d6 = digit_to_glyph(song_display / 8'd100);
                glyph_d5 = digit_to_glyph((song_display / 8'd10) % 8'd10);
                glyph_d4 = digit_to_glyph(song_display % 8'd10);
            end
            default: begin
                glyph_d7 = GLYPH_S;
                glyph_d6 = digit_to_glyph(song_display / 8'd100);
                glyph_d5 = digit_to_glyph((song_display / 8'd10) % 8'd10);
                glyph_d4 = digit_to_glyph(song_display % 8'd10);
            end
        endcase

        glyphs = {glyph_d7, glyph_d6, glyph_d5, glyph_d4,
                  glyph_d3, glyph_d2, glyph_d1, glyph_d0};
        decimal_points = 8'b0000_0100;
        blank = paused && !blink_visible ? 8'b0000_1111 : 8'b0000_0000;
    end

endmodule
