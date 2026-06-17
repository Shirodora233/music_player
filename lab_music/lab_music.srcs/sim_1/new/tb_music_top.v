`timescale 1ns / 1ps

module tb_music_top;

    reg clk;
    reg rst_n;
    reg key_play_pause;
    reg key_stop;
    reg key_next;
    reg key_volume_down;
    reg key_volume_up;
    wire beep;
    wire [31:0] led;
    wire [31:0] seg;
    wire [7:0] seg_cs;

    integer errors;
    integer beep_edges;
    reg [7:0] paused_index;

    music_top #(
        .CLK_FREQ_HZ(100_000),
        .NOTE_GAP_MS(1),
        .DEBOUNCE_MS(1),
        .KEY_ACTIVE_LOW(1)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .key_play_pause(key_play_pause),
        .key_stop(key_stop),
        .key_next(key_next),
        .key_volume_down(key_volume_down),
        .key_volume_up(key_volume_up),
        .beep(beep),
        .led(led),
        .seg(seg),
        .seg_cs(seg_cs)
    );

    always #5000 clk = ~clk;
    always @(posedge beep) beep_edges = beep_edges + 1;

    task press_play_pause;
        begin
            key_play_pause = 1'b0;
            repeat (130) @(posedge clk);
            key_play_pause = 1'b1;
            repeat (130) @(posedge clk);
        end
    endtask

    task press_stop;
        begin
            key_stop = 1'b0;
            repeat (130) @(posedge clk);
            key_stop = 1'b1;
            repeat (130) @(posedge clk);
        end
    endtask

    task press_next;
        begin
            key_next = 1'b0;
            repeat (130) @(posedge clk);
            key_next = 1'b1;
            repeat (130) @(posedge clk);
        end
    endtask

    task press_volume_down;
        begin
            key_volume_down = 1'b0;
            repeat (130) @(posedge clk);
            key_volume_down = 1'b1;
            repeat (130) @(posedge clk);
        end
    endtask

    task press_volume_up;
        begin
            key_volume_up = 1'b0;
            repeat (130) @(posedge clk);
            key_volume_up = 1'b1;
            repeat (130) @(posedge clk);
        end
    endtask

    initial begin
        clk            = 1'b0;
        rst_n          = 1'b0;
        key_play_pause = 1'b1;
        key_stop       = 1'b1;
        key_next       = 1'b1;
        key_volume_down = 1'b1;
        key_volume_up   = 1'b1;
        errors         = 0;
        beep_edges     = 0;

        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (10) @(posedge clk);

        if ((dut.semitone_pitch != 8'd60) ||
            (dut.display_note_name != 3'd0) ||
            (dut.display_accidental != 2'd1) ||
            (dut.display_octave != 4'd4)) begin
            $display("ERROR: initial pitch did not decode as natural C4");
            errors = errors + 1;
        end

        if ((dut.led_row0 != 8'b0000_0001) ||
            (dut.led_row1 != 8'b0000_1000) ||
            (dut.led_row2[1:0] != 2'b00)) begin
            $display("ERROR: LED panel did not show natural C4");
            errors = errors + 1;
        end

        if (dut.current_bpm != 8'd120) begin
            $display("ERROR: default BPM did not load from song metadata");
            errors = errors + 1;
        end

        if ((seg_cs != 8'b1111_1110) || (seg[31:24] != 8'b0111_1111)) begin
            $display("ERROR: seven-segment scanner did not start on rightmost digit 8");
            errors = errors + 1;
        end

        press_play_pause;
        if (!dut.playing) begin
            $display("ERROR: play key did not start playback");
            errors = errors + 1;
        end

        repeat (500) @(posedge clk);
        if (beep_edges == 0) begin
            $display("ERROR: tone generator did not toggle beep");
            errors = errors + 1;
        end

        if (dut.volume_level != 3'd4) begin
            $display("ERROR: reset volume is not maximum");
            errors = errors + 1;
        end

        press_volume_up;
        repeat (10) @(posedge clk);
        if ((dut.selected_song != 1'b1) || !dut.stopped || (dut.note_index != 0)) begin
            $display("ERROR: song parameter increment did not select and stop at song 1");
            errors = errors + 1;
        end

        press_volume_down;
        repeat (10) @(posedge clk);
        if ((dut.selected_song != 1'b0) || (dut.note_index != 0)) begin
            $display("ERROR: song parameter decrement did not wrap back to song 0");
            errors = errors + 1;
        end

        press_next;
        if (dut.edit_mode != 2'd1) begin
            $display("ERROR: next key did not select transpose edit mode");
            errors = errors + 1;
        end

        press_volume_up;
        repeat (10) @(posedge clk);
        if ((dut.transpose_semitones != 6'sd1) ||
            (dut.semitone_pitch != 8'd61) ||
            (dut.display_note_name != 3'd1) ||
            (dut.display_accidental != 2'd0) ||
            (dut.led_row0 != 8'b0000_0010) ||
            (dut.led_row2[1:0] != 2'b01)) begin
            $display("ERROR: transpose increment did not produce Db4");
            errors = errors + 1;
        end

        press_volume_down;
        repeat (10) @(posedge clk);
        if ((dut.transpose_semitones != 6'sd0) || (dut.semitone_pitch != 8'd60)) begin
            $display("ERROR: transpose decrement did not return to C4");
            errors = errors + 1;
        end

        press_next;
        if (dut.edit_mode != 2'd2) begin
            $display("ERROR: next key did not select BPM edit mode");
            errors = errors + 1;
        end

        press_volume_up;
        repeat (10) @(posedge clk);
        if (dut.current_bpm != 8'd121) begin
            $display("ERROR: BPM increment did not reach 121");
            errors = errors + 1;
        end

        press_volume_down;
        repeat (10) @(posedge clk);
        if (dut.current_bpm != 8'd120) begin
            $display("ERROR: BPM decrement did not return to 120");
            errors = errors + 1;
        end

        press_next;
        if (dut.edit_mode != 2'd0) begin
            $display("ERROR: next key did not return to song edit mode");
            errors = errors + 1;
        end

        press_play_pause;
        if (!dut.playing) begin
            $display("ERROR: play key did not restart playback after UI edits");
            errors = errors + 1;
        end

        press_play_pause;
        paused_index = dut.note_index;
        repeat (300) @(posedge clk);
        if (!dut.paused || (beep !== 1'b0) || (dut.note_index != paused_index)) begin
            $display("ERROR: pause did not preserve the current note");
            errors = errors + 1;
        end

        press_play_pause;
        press_stop;
        if (!dut.stopped || (dut.note_index != 0) || (beep !== 1'b0)) begin
            $display("ERROR: stop key did not reset playback");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("PASS: music player control, tone, pitch, and UI tests completed");
        else
            $display("FAIL: %0d test(s) failed", errors);

        $finish;
    end

endmodule
