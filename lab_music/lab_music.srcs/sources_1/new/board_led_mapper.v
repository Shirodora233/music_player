`timescale 1ns / 1ps

module board_led_mapper (
    input  wire [7:0] row0,
    input  wire [7:0] row1,
    input  wire [7:0] row2,
    input  wire [7:0] row3,
    output wire [31:0] led
);

    // Logical rows are ordered left-to-right as seen in the supplied board photo.
    // led[0] maps to the schematic net LED1, led[31] maps to LED32.
    assign led[0]  = row1[7]; // D25 / LED1
    assign led[1]  = row1[0]; // D18 / LED2
    assign led[2]  = row1[6]; // D24 / LED3
    assign led[3]  = row1[5]; // D23 / LED4
    assign led[4]  = row0[1]; // D9  / LED5
    assign led[5]  = row0[2]; // D10 / LED6
    assign led[6]  = row0[3]; // D11 / LED7
    assign led[7]  = row0[4]; // D12 / LED8
    assign led[8]  = row2[1]; // D27 / LED9
    assign led[9]  = row2[0]; // D26 / LED10
    assign led[10] = row2[3]; // D29 / LED11
    assign led[11] = row2[5]; // D31 / LED12
    assign led[12] = row3[0]; // D34 / LED13
    assign led[13] = row3[2]; // D36 / LED14
    assign led[14] = row3[1]; // D35 / LED15
    assign led[15] = row3[3]; // D37 / LED16
    assign led[16] = row1[4]; // D22 / LED17
    assign led[17] = row1[3]; // D21 / LED18
    assign led[18] = row1[2]; // D20 / LED19
    assign led[19] = row1[1]; // D19 / LED20
    assign led[20] = row0[7]; // D15 / LED21
    assign led[21] = row0[5]; // D13 / LED22
    assign led[22] = row0[0]; // D8  / LED23
    assign led[23] = row0[6]; // D14 / LED24
    assign led[24] = row2[2]; // D28 / LED25
    assign led[25] = row2[4]; // D30 / LED26
    assign led[26] = row2[6]; // D32 / LED27
    assign led[27] = row2[7]; // D33 / LED28
    assign led[28] = row3[4]; // D38 / LED29
    assign led[29] = row3[6]; // D40 / LED30
    assign led[30] = row3[5]; // D39 / LED31
    assign led[31] = row3[7]; // D41 / LED32

endmodule
