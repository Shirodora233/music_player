`timescale 1ns / 1ps

module beat_controller #(
    parameter integer CLK_FREQ_HZ = 200_000_000,
    parameter integer NOTE_GAP_MS = 20
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       enable,
    input  wire       clear,
    input  wire [7:0] bpm,
    input  wire [5:0] duration_16th,
    output wire       note_done,
    output wire       tone_enable,
    output wire       sixteenth_pulse,
    output wire       beat_pulse
);

    localparam [31:0] GAP_TICKS = (CLK_FREQ_HZ / 1000) * NOTE_GAP_MS;

    wire [7:0] bpm_safe = (bpm == 0) ? 8'd1 : bpm;
    wire [63:0] ticks_per_16th_wide = (64'd15 * CLK_FREQ_HZ) / bpm_safe;
    wire [31:0] ticks_per_16th = (ticks_per_16th_wide == 0) ?
                                 32'd1 : ticks_per_16th_wide[31:0];
    wire [31:0] effective_gap_ticks =
        (GAP_TICKS < ticks_per_16th) ? GAP_TICKS : 32'd0;

    reg [31:0] sixteenth_tick_count;
    reg [5:0] elapsed_16ths;
    reg [1:0] beat_phase;
    wire sixteenth_last_tick;
    wire final_16th;

    assign sixteenth_last_tick = (ticks_per_16th <= 1) ||
                                 (sixteenth_tick_count >= ticks_per_16th - 1);
    assign final_16th = (duration_16th <= 1) ||
                        (elapsed_16ths >= duration_16th - 1'b1);
    assign sixteenth_pulse = enable && (duration_16th != 0) && sixteenth_last_tick;
    assign beat_pulse = sixteenth_pulse && (beat_phase == 2'd3);
    assign note_done = sixteenth_pulse && final_16th;
    assign tone_enable = enable && (duration_16th != 0) &&
                         ((effective_gap_ticks == 0) || !final_16th ||
                          (sixteenth_tick_count < ticks_per_16th - effective_gap_ticks));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sixteenth_tick_count <= 32'd0;
            elapsed_16ths        <= 6'd0;
            beat_phase           <= 2'd0;
        end else if (clear) begin
            sixteenth_tick_count <= 32'd0;
            elapsed_16ths        <= 6'd0;
            beat_phase           <= 2'd0;
        end else if (enable) begin
            if (duration_16th == 0) begin
                sixteenth_tick_count <= 32'd0;
                elapsed_16ths        <= 6'd0;
            end else if (sixteenth_last_tick) begin
                sixteenth_tick_count <= 32'd0;

                if (beat_phase == 2'd3)
                    beat_phase <= 2'd0;
                else
                    beat_phase <= beat_phase + 1'b1;

                if (final_16th)
                    elapsed_16ths <= 6'd0;
                else
                    elapsed_16ths <= elapsed_16ths + 1'b1;
            end else begin
                sixteenth_tick_count <= sixteenth_tick_count + 1'b1;
            end
        end
    end

endmodule
