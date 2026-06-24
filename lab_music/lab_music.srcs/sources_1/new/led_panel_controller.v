`timescale 1ns / 1ps

module led_panel_controller #(
    parameter integer CLK_FREQ_HZ = 200_000_000
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        is_rest,
    input  wire [2:0]  display_note_name,
    input  wire [1:0]  display_accidental,
    input  wire [3:0]  display_octave,
    input  wire [2:0]  beats_per_bar,
    input  wire [1:0]  beat_in_bar,
    input  wire [15:0] elapsed_units,
    input  wire [15:0] total_duration_units,
    output reg  [7:0]  row0,
    output reg  [7:0]  row1,
    output reg  [7:0]  row2,
    output wire [7:0]  row3
);

    localparam [1:0] ACC_FLAT    = 2'd0;
    localparam [1:0] ACC_NATURAL = 2'd1;
    localparam [1:0] ACC_SHARP   = 2'd2;

    wire [31:0] progress_scaled = {13'd0, elapsed_units, 3'd0};
    wire [31:0] total_duration_ext = {16'd0, total_duration_units};

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

    always @(*) begin
        row2 = 8'b0000_0000;
        row2[0] = !is_rest && (display_accidental == ACC_FLAT);
        row2[1] = !is_rest && (display_accidental == ACC_SHARP);

        case (beats_per_bar)
            3'd2: begin
                if (beat_in_bar == 2'd0)
                    row2[6] = 1'b1;
                else
                    row2[7] = 1'b1;
            end
            3'd3: begin
                case (beat_in_bar)
                    2'd0: row2[5] = 1'b1;
                    2'd1: row2[6] = 1'b1;
                    default: row2[7] = 1'b1;
                endcase
            end
            default: begin
                case (beat_in_bar)
                    2'd0: row2[4] = 1'b1;
                    2'd1: row2[5] = 1'b1;
                    2'd2: row2[6] = 1'b1;
                    default: row2[7] = 1'b1;
                endcase
            end
        endcase
    end

    assign row3[0] = (total_duration_units != 0) &&
                     (progress_scaled >= total_duration_ext);
    assign row3[1] = (total_duration_units != 0) &&
                     (progress_scaled >= (total_duration_ext << 1));
    assign row3[2] = (total_duration_units != 0) &&
                     (progress_scaled >= (total_duration_ext * 3));
    assign row3[3] = (total_duration_units != 0) &&
                     (progress_scaled >= (total_duration_ext << 2));
    assign row3[4] = (total_duration_units != 0) &&
                     (progress_scaled >= (total_duration_ext * 5));
    assign row3[5] = (total_duration_units != 0) &&
                     (progress_scaled >= (total_duration_ext * 6));
    assign row3[6] = (total_duration_units != 0) &&
                     (progress_scaled >= (total_duration_ext * 7));
    assign row3[7] = (total_duration_units != 0) &&
                     (progress_scaled >= (total_duration_ext << 3));

endmodule
