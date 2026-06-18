`timescale 1ns / 1ps

module key_repeat #(
    parameter integer CLK_FREQ_HZ       = 200_000_000,
    parameter integer INITIAL_DELAY_MS  = 500,
    parameter integer REPEAT_MS         = 120,
    parameter integer FAST_DELAY_MS     = 2000,
    parameter integer FAST_REPEAT_MS    = 40
)(
    input  wire clk,
    input  wire rst_n,
    input  wire key_state,
    input  wire key_pressed,
    output reg  repeat_pressed
);

    localparam integer INITIAL_DELAY_RAW = (CLK_FREQ_HZ / 1000) * INITIAL_DELAY_MS;
    localparam integer REPEAT_RAW        = (CLK_FREQ_HZ / 1000) * REPEAT_MS;
    localparam integer FAST_DELAY_RAW    = (CLK_FREQ_HZ / 1000) * FAST_DELAY_MS;
    localparam integer FAST_REPEAT_RAW   = (CLK_FREQ_HZ / 1000) * FAST_REPEAT_MS;
    localparam integer INITIAL_DELAY_TICKS = (INITIAL_DELAY_RAW < 1) ? 1 : INITIAL_DELAY_RAW;
    localparam integer REPEAT_TICKS        = (REPEAT_RAW < 1) ? 1 : REPEAT_RAW;
    localparam integer FAST_DELAY_TICKS    = (FAST_DELAY_RAW < 1) ? 1 : FAST_DELAY_RAW;
    localparam integer FAST_REPEAT_TICKS   = (FAST_REPEAT_RAW < 1) ? 1 : FAST_REPEAT_RAW;

    reg [31:0] hold_count;
    reg [31:0] repeat_count;
    wire fast_phase = (hold_count >= FAST_DELAY_TICKS - 1);
    wire [31:0] active_repeat_ticks = fast_phase ? FAST_REPEAT_TICKS : REPEAT_TICKS;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hold_count     <= 32'd0;
            repeat_count   <= 32'd0;
            repeat_pressed <= 1'b0;
        end else begin
            repeat_pressed <= key_pressed;

            if (!key_state) begin
                hold_count   <= 32'd0;
                repeat_count <= 32'd0;
            end else begin
                if (hold_count < 32'hFFFF_FFFF)
                    hold_count <= hold_count + 1'b1;

                if (hold_count < INITIAL_DELAY_TICKS - 1) begin
                    repeat_count <= 32'd0;
                end else if (repeat_count >= active_repeat_ticks - 1) begin
                    repeat_count <= 32'd0;
                    repeat_pressed <= 1'b1;
                end else begin
                    repeat_count <= repeat_count + 1'b1;
                end
            end
        end
    end

endmodule
