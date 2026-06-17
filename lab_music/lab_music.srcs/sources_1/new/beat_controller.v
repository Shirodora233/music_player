`timescale 1ns / 1ps

module beat_controller #(
    parameter integer CLK_FREQ_HZ = 200_000_000,
    parameter integer BEAT_MS     = 500,
    parameter integer NOTE_GAP_MS = 20
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       enable,
    input  wire       clear,
    input  wire [3:0] duration_beats,
    output wire       note_done,
    output wire       tone_enable
);

    localparam integer TICKS_PER_BEAT = (CLK_FREQ_HZ / 1000) * BEAT_MS;
    localparam integer GAP_TICKS      = (CLK_FREQ_HZ / 1000) * NOTE_GAP_MS;
    localparam integer EFFECTIVE_GAP_TICKS =
        (GAP_TICKS < TICKS_PER_BEAT) ? GAP_TICKS : 0;

    reg [31:0] beat_tick_count;
    reg [3:0] elapsed_beats;
    wire beat_last_tick;
    wire final_beat;

    assign beat_last_tick = (TICKS_PER_BEAT <= 1) ||
                            (beat_tick_count >= TICKS_PER_BEAT - 1);
    assign final_beat = (duration_beats <= 1) ||
                        (elapsed_beats >= duration_beats - 1'b1);
    assign note_done = enable && (duration_beats != 0) &&
                       final_beat && beat_last_tick;
    assign tone_enable = enable && (duration_beats != 0) &&
                         ((EFFECTIVE_GAP_TICKS == 0) || !final_beat ||
                          (beat_tick_count < TICKS_PER_BEAT - EFFECTIVE_GAP_TICKS));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            beat_tick_count <= 32'd0;
            elapsed_beats   <= 4'd0;
        end else if (clear) begin
            beat_tick_count <= 32'd0;
            elapsed_beats   <= 4'd0;
        end else if (enable) begin
            if (duration_beats == 0) begin
                beat_tick_count <= 32'd0;
                elapsed_beats   <= 4'd0;
            end else if (beat_last_tick) begin
                beat_tick_count <= 32'd0;
                if (final_beat)
                    elapsed_beats <= 4'd0;
                else
                    elapsed_beats <= elapsed_beats + 1'b1;
            end else begin
                beat_tick_count <= beat_tick_count + 1'b1;
            end
        end
    end

endmodule
