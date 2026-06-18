`timescale 1ns / 1ps

module self_test_controller #(
    parameter integer CLK_FREQ_HZ = 200_000_000,
    parameter integer STEP_MS     = 100,
    parameter integer BEEP_HZ     = 880
)(
    input  wire        clk,
    input  wire        rst_n,
    output wire [31:0] led,
    output wire [39:0] glyphs,
    output wire [7:0]  decimal_points,
    output wire [7:0]  blank,
    output reg         beep
);

    localparam integer STEP_RAW = (CLK_FREQ_HZ / 1000) * STEP_MS;
    localparam integer STEP_TICKS = (STEP_RAW < 1) ? 1 : STEP_RAW;
    localparam integer BEEP_HALF_RAW = CLK_FREQ_HZ / (BEEP_HZ * 2);
    localparam integer BEEP_HALF_TICKS = (BEEP_HALF_RAW < 1) ? 1 : BEEP_HALF_RAW;

    reg [31:0] step_counter;
    reg [4:0]  led_index;
    reg [31:0] beep_counter;

    assign led = 32'd1 << led_index;
    assign glyphs = {5'd0, 5'd1, 5'd2, 5'd3, 5'd4, 5'd5, 5'd6, 5'd7};
    assign decimal_points = 8'b0000_0000;
    assign blank = 8'b0000_0000;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            step_counter <= 32'd0;
            led_index    <= 5'd0;
        end else if (step_counter >= STEP_TICKS - 1) begin
            step_counter <= 32'd0;
            led_index    <= led_index + 1'b1;
        end else begin
            step_counter <= step_counter + 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            beep_counter <= 32'd0;
            beep         <= 1'b0;
        end else if (beep_counter >= BEEP_HALF_TICKS - 1) begin
            beep_counter <= 32'd0;
            beep         <= ~beep;
        end else begin
            beep_counter <= beep_counter + 1'b1;
        end
    end

endmodule
