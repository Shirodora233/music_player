`timescale 1ns / 1ps

module tone_generator #(
    parameter integer CLK_FREQ_HZ = 200_000_000
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       enable,
    input  wire [4:0] note_code,
    input  wire [2:0] volume_level,
    output wire       beep
);

    localparam [4:0] NOTE_REST = 5'd0;
    localparam [4:0] NOTE_C4   = 5'd1;
    localparam [4:0] NOTE_D4   = 5'd2;
    localparam [4:0] NOTE_E4   = 5'd3;
    localparam [4:0] NOTE_F4   = 5'd4;
    localparam [4:0] NOTE_G4   = 5'd5;
    localparam [4:0] NOTE_A4   = 5'd6;
    localparam [4:0] NOTE_B4   = 5'd7;
    localparam [4:0] NOTE_C5   = 5'd8;

    reg [31:0] period_count;
    reg [4:0] previous_note;
    reg [31:0] period_ticks;
    reg [31:0] high_ticks;

    always @(*) begin
        case (note_code)
            NOTE_C4:   period_ticks = CLK_FREQ_HZ / 262;
            NOTE_D4:   period_ticks = CLK_FREQ_HZ / 294;
            NOTE_E4:   period_ticks = CLK_FREQ_HZ / 330;
            NOTE_F4:   period_ticks = CLK_FREQ_HZ / 349;
            NOTE_G4:   period_ticks = CLK_FREQ_HZ / 392;
            NOTE_A4:   period_ticks = CLK_FREQ_HZ / 440;
            NOTE_B4:   period_ticks = CLK_FREQ_HZ / 494;
            NOTE_C5:   period_ticks = CLK_FREQ_HZ / 523;
            default:   period_ticks = 32'd0;
        endcase

        case (volume_level)
            3'd1: high_ticks = period_ticks >> 3;                         // 12.5%
            3'd2: high_ticks = period_ticks >> 2;                         // 25.0%
            3'd3: high_ticks = (period_ticks >> 2) + (period_ticks >> 3); // 37.5%
            3'd4: high_ticks = period_ticks >> 1;                         // 50.0%
            default: high_ticks = 32'd0;                                  // mute
        endcase
    end

    assign beep = enable && (note_code != NOTE_REST) &&
                  (period_ticks != 0) && (high_ticks != 0) &&
                  (period_count < high_ticks);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            period_count  <= 32'd0;
            previous_note <= NOTE_REST;
        end else if (!enable || (note_code == NOTE_REST) || (period_ticks == 0)) begin
            period_count  <= 32'd0;
            previous_note <= note_code;
        end else if (note_code != previous_note) begin
            period_count  <= 32'd0;
            previous_note <= note_code;
        end else if (period_count >= period_ticks - 1'b1) begin
            period_count <= 32'd0;
        end else begin
            period_count <= period_count + 1'b1;
        end
    end

endmodule
