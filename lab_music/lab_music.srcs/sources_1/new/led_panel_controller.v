`timescale 1ns / 1ps

module led_panel_controller #(
    parameter integer CLK_FREQ_HZ = 200_000_000,
    parameter integer BEAT_FLASH_MS = 80
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        is_rest,
    input  wire [2:0]  display_note_name,
    input  wire [1:0]  display_accidental,
    input  wire [3:0]  display_octave,
    input  wire        beat_pulse,
    input  wire [15:0] elapsed_16th_units,
    input  wire [15:0] total_duration_16th,
    output reg  [7:0]  row0,
    output reg  [7:0]  row1,
    output wire [7:0]  row2,
    output wire [7:0]  row3
);

    localparam [1:0] ACC_FLAT    = 2'd0;
    localparam [1:0] ACC_NATURAL = 2'd1;
    localparam [1:0] ACC_SHARP   = 2'd2;
    localparam [31:0] BEAT_FLASH_TICKS =
        ((CLK_FREQ_HZ / 1000) * BEAT_FLASH_MS);

    reg [31:0] beat_flash_count;
    wire beat_flash_on = (beat_flash_count != 0);
    wire [31:0] progress_scaled = {13'd0, elapsed_16th_units, 3'd0};
    wire [31:0] total_duration_ext = {16'd0, total_duration_16th};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            beat_flash_count <= 32'd0;
        end else if (beat_pulse) begin
            beat_flash_count <= (BEAT_FLASH_TICKS == 0) ? 32'd1 : BEAT_FLASH_TICKS;
        end else if (beat_flash_count != 0) begin
            beat_flash_count <= beat_flash_count - 1'b1;
        end
    end

    always @(*) begin
        row0 = 8'b0000_0000;
        if (!is_rest && (display_note_name < 3'd7))
            row0[display_note_name] = 1'b1;
    end

    always @(*) begin
        row1 = 8'b0000_0000;
        if (!is_rest && (display_octave > 0) && (display_octave <= 8))
            row1[display_octave - 1'b1] = 1'b1;
    end

    assign row2[0] = !is_rest && (display_accidental == ACC_FLAT);
    assign row2[1] = !is_rest && (display_accidental == ACC_SHARP);
    assign row2[6:2] = 5'b00000;
    assign row2[7] = beat_flash_on;

    assign row3[0] = (total_duration_16th != 0) &&
                     (progress_scaled >= total_duration_ext);
    assign row3[1] = (total_duration_16th != 0) &&
                     (progress_scaled >= (total_duration_ext << 1));
    assign row3[2] = (total_duration_16th != 0) &&
                     (progress_scaled >= (total_duration_ext * 3));
    assign row3[3] = (total_duration_16th != 0) &&
                     (progress_scaled >= (total_duration_ext << 2));
    assign row3[4] = (total_duration_16th != 0) &&
                     (progress_scaled >= (total_duration_ext * 5));
    assign row3[5] = (total_duration_16th != 0) &&
                     (progress_scaled >= (total_duration_ext * 6));
    assign row3[6] = (total_duration_16th != 0) &&
                     (progress_scaled >= (total_duration_ext * 7));
    assign row3[7] = (total_duration_16th != 0) &&
                     (progress_scaled >= (total_duration_ext << 3));

endmodule
