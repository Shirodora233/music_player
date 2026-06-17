`timescale 1ns / 1ps

module song_rom (
    input  wire [0:0] song_select,
    input  wire [5:0] note_index,
    output reg  [4:0] note_code,
    output reg  [3:0] duration_beats,
    output reg  [5:0] song_length
);

    localparam [4:0] REST = 5'd0;
    localparam [4:0] C4   = 5'd1;
    localparam [4:0] D4   = 5'd2;
    localparam [4:0] E4   = 5'd3;
    localparam [4:0] F4   = 5'd4;
    localparam [4:0] G4   = 5'd5;
    localparam [4:0] A4   = 5'd6;

    always @(*) begin
        note_code      = REST;
        duration_beats = 4'd1;

        if (song_select == 1'b0) begin
            // Song 0: Twinkle Twinkle Little Star, 4/4 time.
            song_length = 6'd42;
            case (note_index)
                6'd0,  6'd1:  note_code = C4;
                6'd2,  6'd3:  note_code = G4;
                6'd4,  6'd5:  note_code = A4;
                6'd6:  begin note_code = G4; duration_beats = 4'd2; end
                6'd7,  6'd8:  note_code = F4;
                6'd9,  6'd10: note_code = E4;
                6'd11, 6'd12: note_code = D4;
                6'd13: begin note_code = C4; duration_beats = 4'd2; end
                6'd14, 6'd15: note_code = G4;
                6'd16, 6'd17: note_code = F4;
                6'd18, 6'd19: note_code = E4;
                6'd20: begin note_code = D4; duration_beats = 4'd2; end
                6'd21, 6'd22: note_code = G4;
                6'd23, 6'd24: note_code = F4;
                6'd25, 6'd26: note_code = E4;
                6'd27: begin note_code = D4; duration_beats = 4'd2; end
                6'd28, 6'd29: note_code = C4;
                6'd30, 6'd31: note_code = G4;
                6'd32, 6'd33: note_code = A4;
                6'd34: begin note_code = G4; duration_beats = 4'd2; end
                6'd35, 6'd36: note_code = F4;
                6'd37, 6'd38: note_code = E4;
                6'd39, 6'd40: note_code = D4;
                6'd41: begin note_code = C4; duration_beats = 4'd2; end
                default: note_code = REST;
            endcase
        end else begin
            // Song 1: Two Tigers, 4/4 time.
            song_length = 6'd32;
            case (note_index)
                6'd0,  6'd4:  note_code = C4;
                6'd1,  6'd5:  note_code = D4;
                6'd2,  6'd6:  note_code = E4;
                6'd3,  6'd7:  note_code = C4;
                6'd8,  6'd11: note_code = E4;
                6'd9,  6'd12: note_code = F4;
                6'd10, 6'd13: begin note_code = G4; duration_beats = 4'd2; end
                6'd14, 6'd20: note_code = G4;
                6'd15, 6'd21: note_code = A4;
                6'd16, 6'd22: note_code = G4;
                6'd17, 6'd23: note_code = F4;
                6'd18, 6'd24: note_code = E4;
                6'd19, 6'd25: note_code = C4;
                6'd26, 6'd29: note_code = C4;
                6'd27, 6'd30: note_code = G4;
                6'd28, 6'd31: begin note_code = C4; duration_beats = 4'd2; end
                default: note_code = REST;
            endcase
        end
    end

endmodule
