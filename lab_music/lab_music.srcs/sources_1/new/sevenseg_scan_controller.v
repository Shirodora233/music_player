`timescale 1ns / 1ps

module sevenseg_scan_controller #(
    parameter integer CLK_FREQ_HZ     = 200_000_000,
    parameter integer SCAN_HZ         = 8_000,
    parameter integer SEG_ACTIVE_HIGH = 1,
    parameter integer CS_ACTIVE_LOW   = 1
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [39:0] glyphs,
    input  wire [7:0]  decimal_points,
    input  wire [7:0]  blank,
    output reg  [31:0] seg,
    output reg  [7:0]  seg_cs
);

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

    localparam integer SCAN_TICKS_RAW = CLK_FREQ_HZ / SCAN_HZ;
    localparam integer SCAN_TICKS     = (SCAN_TICKS_RAW < 1) ? 1 : SCAN_TICKS_RAW;

    reg [31:0] scan_counter;
    reg [2:0]  active_digit;
    reg [4:0]  active_glyph;
    reg [7:0]  raw_segments;
    reg [7:0]  driven_segments;
    reg [7:0]  raw_cs;

    function [7:0] decode_glyph;
        input [4:0] glyph;
        begin
            case (glyph)
                GLYPH_0:     decode_glyph = 8'b0011_1111;
                GLYPH_1:     decode_glyph = 8'b0000_0110;
                GLYPH_2:     decode_glyph = 8'b0101_1011;
                GLYPH_3:     decode_glyph = 8'b0100_1111;
                GLYPH_4:     decode_glyph = 8'b0110_0110;
                GLYPH_5:     decode_glyph = 8'b0110_1101;
                GLYPH_6:     decode_glyph = 8'b0111_1101;
                GLYPH_7:     decode_glyph = 8'b0000_0111;
                GLYPH_8:     decode_glyph = 8'b0111_1111;
                GLYPH_9:     decode_glyph = 8'b0110_1111;
                GLYPH_MINUS: decode_glyph = 8'b0100_0000;
                GLYPH_S:     decode_glyph = 8'b0110_1101;
                GLYPH_T:     decode_glyph = 8'b0111_1000;
                GLYPH_B:     decode_glyph = 8'b0111_1100;
                GLYPH_PLUS:  decode_glyph = 8'b0110_0010;
                GLYPH_BLANK: decode_glyph = 8'b0000_0000;
                default:     decode_glyph = 8'b0000_0000;
            endcase
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_counter <= 32'd0;
            active_digit <= 3'd0;
        end else if (scan_counter >= SCAN_TICKS - 1) begin
            scan_counter <= 32'd0;
            active_digit <= active_digit + 1'b1;
        end else begin
            scan_counter <= scan_counter + 1'b1;
        end
    end

    always @* begin
        case (active_digit)
            3'd0: active_glyph = glyphs[4:0];
            3'd1: active_glyph = glyphs[9:5];
            3'd2: active_glyph = glyphs[14:10];
            3'd3: active_glyph = glyphs[19:15];
            3'd4: active_glyph = glyphs[24:20];
            3'd5: active_glyph = glyphs[29:25];
            3'd6: active_glyph = glyphs[34:30];
            3'd7: active_glyph = glyphs[39:35];
            default: active_glyph = GLYPH_BLANK;
        endcase

        if (blank[active_digit]) begin
            raw_segments = 8'b0000_0000;
        end else begin
            raw_segments = decode_glyph(active_glyph);
            raw_segments[7] = raw_segments[7] | decimal_points[active_digit];
        end
        driven_segments = SEG_ACTIVE_HIGH ? raw_segments : ~raw_segments;

        raw_cs = 8'b0000_0000;
        raw_cs[active_digit] = 1'b1;
        seg_cs = CS_ACTIVE_LOW ? ~raw_cs : raw_cs;

        seg = SEG_ACTIVE_HIGH ? 32'h0000_0000 : 32'hFFFF_FFFF;
        case (active_digit)
            3'd0,
            3'd1: seg[31:24] = driven_segments;
            3'd2,
            3'd3: seg[23:16] = driven_segments;
            3'd4,
            3'd5: seg[15:8] = driven_segments;
            3'd6,
            3'd7: seg[7:0] = driven_segments;
            default: seg = SEG_ACTIVE_HIGH ? 32'h0000_0000 : 32'hFFFF_FFFF;
        endcase
    end

endmodule
