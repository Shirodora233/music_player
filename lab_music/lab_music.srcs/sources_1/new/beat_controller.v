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
    input  wire [6:0] duration_units,
    output wire       note_done,
    output wire       tone_enable,
    output wire       unit_pulse,
    output wire       beat_pulse
);

    localparam [31:0] GAP_TICKS = (CLK_FREQ_HZ / 1000) * NOTE_GAP_MS;

    wire [7:0] bpm_safe = (bpm == 0) ? 8'd1 : bpm;
    wire [63:0] ticks_per_unit_wide = (64'd5 * CLK_FREQ_HZ) / bpm_safe;
    wire [31:0] ticks_per_unit = (ticks_per_unit_wide == 0) ?
                                 32'd1 : ticks_per_unit_wide[31:0];
    wire [31:0] effective_gap_ticks =
        (GAP_TICKS < ticks_per_unit) ? GAP_TICKS : 32'd0;

    reg [31:0] unit_tick_count;
    reg [6:0] elapsed_units;
    reg [3:0] beat_phase;
    wire unit_last_tick;
    wire final_unit;

    assign unit_last_tick = (ticks_per_unit <= 1) ||
                            (unit_tick_count >= ticks_per_unit - 1);
    assign final_unit = (duration_units <= 1) ||
                        (elapsed_units >= duration_units - 1'b1);
    assign unit_pulse = enable && (duration_units != 0) && unit_last_tick;
    assign beat_pulse = unit_pulse && (beat_phase == 4'd11);
    assign note_done = unit_pulse && final_unit;
    assign tone_enable = enable && (duration_units != 0) &&
                         ((effective_gap_ticks == 0) || !final_unit ||
                          (unit_tick_count < ticks_per_unit - effective_gap_ticks));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            unit_tick_count      <= 32'd0;
            elapsed_units        <= 7'd0;
            beat_phase           <= 4'd0;
        end else if (clear) begin
            unit_tick_count      <= 32'd0;
            elapsed_units        <= 7'd0;
            beat_phase           <= 4'd0;
        end else if (enable) begin
            if (duration_units == 0) begin
                unit_tick_count      <= 32'd0;
                elapsed_units        <= 7'd0;
            end else if (unit_last_tick) begin
                unit_tick_count <= 32'd0;

                if (beat_phase == 4'd11)
                    beat_phase <= 4'd0;
                else
                    beat_phase <= beat_phase + 1'b1;

                if (final_unit)
                    elapsed_units <= 7'd0;
                else
                    elapsed_units <= elapsed_units + 1'b1;
            end else begin
                unit_tick_count <= unit_tick_count + 1'b1;
            end
        end
    end

endmodule
