`timescale 1ns / 1ps

module long_press_toggle #(
    parameter integer CLK_FREQ_HZ   = 200_000_000,
    parameter integer LONG_PRESS_MS = 1000
)(
    input  wire clk,
    input  wire rst_n,
    input  wire key_state,
    output reg  toggle_pulse
);

    localparam integer LONG_PRESS_RAW = (CLK_FREQ_HZ / 1000) * LONG_PRESS_MS;
    localparam integer LONG_PRESS_TICKS = (LONG_PRESS_RAW < 1) ? 1 : LONG_PRESS_RAW;

    reg [31:0] hold_count;
    reg        fired;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hold_count   <= 32'd0;
            fired        <= 1'b0;
            toggle_pulse <= 1'b0;
        end else begin
            toggle_pulse <= 1'b0;

            if (!key_state) begin
                hold_count <= 32'd0;
                fired      <= 1'b0;
            end else if (!fired) begin
                if (hold_count >= LONG_PRESS_TICKS - 1) begin
                    hold_count   <= 32'd0;
                    fired        <= 1'b1;
                    toggle_pulse <= 1'b1;
                end else begin
                    hold_count <= hold_count + 1'b1;
                end
            end
        end
    end

endmodule
