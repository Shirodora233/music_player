`timescale 1ns / 1ps

module button_debounce #(
    parameter integer CLK_FREQ_HZ = 200_000_000,
    parameter integer DEBOUNCE_MS = 20
)(
    input  wire clk,
    input  wire rst_n,
    input  wire key_in,
    output reg  key_state,
    output reg  key_pressed
);

    localparam integer COUNT_MAX = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;

    reg key_sync_0;
    reg key_sync_1;
    reg [31:0] stable_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_sync_0 <= 1'b0;
            key_sync_1 <= 1'b0;
        end else begin
            key_sync_0 <= key_in;
            key_sync_1 <= key_sync_0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_state   <= 1'b0;
            key_pressed <= 1'b0;
            stable_count <= 32'd0;
        end else begin
            key_pressed <= 1'b0;

            if (key_sync_1 == key_state) begin
                stable_count <= 32'd0;
            end else if ((COUNT_MAX <= 1) || (stable_count >= COUNT_MAX - 1)) begin
                stable_count <= 32'd0;
                key_state <= key_sync_1;
                if (key_sync_1)
                    key_pressed <= 1'b1;
            end else begin
                stable_count <= stable_count + 1'b1;
            end
        end
    end

endmodule
