`timescale 1ns / 1ps

module tone_generator #(
    parameter integer CLK_FREQ_HZ = 200_000_000
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       enable,
    input  wire       is_rest,
    input  wire [7:0] semitone_pitch,
    input  wire [2:0] volume_level,
    output wire       beep
);

    reg [31:0] period_count;
    reg [7:0] previous_pitch;
    reg [31:0] base_period_ticks;
    reg [31:0] period_ticks;
    reg [31:0] high_ticks;

    wire [7:0] pitch_class = semitone_pitch % 8'd12;
    wire [7:0] midi_octave = semitone_pitch / 8'd12;
    wire [3:0] tone_octave = (midi_octave == 0) ? 4'd0 :
                             (midi_octave[3:0] - 4'd1);

    always @(*) begin
        case (pitch_class)
            8'd0:  base_period_ticks = CLK_FREQ_HZ / 262; // C4
            8'd1:  base_period_ticks = CLK_FREQ_HZ / 277; // C#4 / Db4
            8'd2:  base_period_ticks = CLK_FREQ_HZ / 294; // D4
            8'd3:  base_period_ticks = CLK_FREQ_HZ / 311; // D#4 / Eb4
            8'd4:  base_period_ticks = CLK_FREQ_HZ / 330; // E4
            8'd5:  base_period_ticks = CLK_FREQ_HZ / 349; // F4
            8'd6:  base_period_ticks = CLK_FREQ_HZ / 370; // F#4 / Gb4
            8'd7:  base_period_ticks = CLK_FREQ_HZ / 392; // G4
            8'd8:  base_period_ticks = CLK_FREQ_HZ / 415; // G#4 / Ab4
            8'd9:  base_period_ticks = CLK_FREQ_HZ / 440; // A4
            8'd10: base_period_ticks = CLK_FREQ_HZ / 466; // A#4 / Bb4
            8'd11: base_period_ticks = CLK_FREQ_HZ / 494; // B4
            default: base_period_ticks = 32'd0;
        endcase

        if (tone_octave > 4'd4)
            period_ticks = base_period_ticks >> (tone_octave - 4'd4);
        else
            period_ticks = base_period_ticks << (4'd4 - tone_octave);

        if (is_rest) begin
            period_ticks = 32'd0;
        end

        case (volume_level)
            3'd1: high_ticks = period_ticks >> 7; // 0.78%
            3'd2: high_ticks = period_ticks >> 6; // 1.56%
            3'd3: high_ticks = period_ticks >> 5; // 3.12%
            3'd4: high_ticks = period_ticks >> 4; // 6.25%
            3'd5: high_ticks = period_ticks >> 3; // 12.5%
            3'd6: high_ticks = period_ticks >> 2; // 25.0%
            3'd7: high_ticks = period_ticks >> 1; // 50.0%
            default: high_ticks = 32'd0;          // mute
        endcase
    end

    assign beep = enable && !is_rest &&
                  (period_ticks != 0) && (high_ticks != 0) &&
                  (period_count < high_ticks);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            period_count  <= 32'd0;
            previous_pitch <= 8'd0;
        end else if (!enable || is_rest || (period_ticks == 0)) begin
            period_count  <= 32'd0;
            previous_pitch <= semitone_pitch;
        end else if (semitone_pitch != previous_pitch) begin
            period_count  <= 32'd0;
            previous_pitch <= semitone_pitch;
        end else if (period_count >= period_ticks - 1'b1) begin
            period_count <= 32'd0;
        end else begin
            period_count <= period_count + 1'b1;
        end
    end

endmodule
