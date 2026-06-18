`timescale 1ns / 1ps

module tb_music_top;

    reg clk;
    reg rst_n;
    reg key_play_pause;
    reg key_stop;
    reg key_next;
    reg key_volume_down;
    reg key_volume_up;
    reg key_display_mode;
    wire beep;
    wire [31:0] led;
    wire [31:0] seg;
    wire [7:0] seg_cs;
    wire [31:0] scan_order_seg;
    wire [7:0] scan_order_cs;

    integer errors;
    integer beep_edges;
    reg [7:0] paused_index;
    reg pm_play_pause;
    reg pm_stop;
    reg pm_song_changed;
    reg pm_auto_song_changed;
    reg pm_note_done;
    reg [1:0] pm_playback_mode;
    wire [7:0] pm_note_index;
    wire pm_playing;
    wire pm_paused;
    wire pm_stopped;

    music_top #(
        .CLK_FREQ_HZ(10_000),
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
        .key_display_mode(key_display_mode),
        .beep(beep),
        .led(led),
        .seg(seg),
        .seg_cs(seg_cs)
    );

    sevenseg_scan_controller #(
        .CLK_FREQ_HZ(10_000)
    ) u_scan_order_check (
        .clk(clk),
        .rst_n(rst_n),
        .glyphs({5'd12, 5'd0, 5'd0, 5'd1, 5'd0, 5'd1, 5'd1, 5'd2}),
        .decimal_points(8'b0000_0100),
        .blank(8'b0000_0000),
        .seg(scan_order_seg),
        .seg_cs(scan_order_cs)
    );

    player_controller u_player_mode_check (
        .clk(clk),
        .rst_n(rst_n),
        .play_pause_pressed(pm_play_pause),
        .stop_pressed(pm_stop),
        .song_changed(pm_song_changed),
        .auto_song_changed(pm_auto_song_changed),
        .note_done(pm_note_done),
        .song_length(8'd2),
        .playback_mode(pm_playback_mode),
        .note_index(pm_note_index),
        .playing(pm_playing),
        .paused(pm_paused),
        .stopped(pm_stopped)
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

    task press_display_mode;
        begin
            key_display_mode = 1'b0;
            repeat (130) @(posedge clk);
            key_display_mode = 1'b1;
            repeat (130) @(posedge clk);
        end
    endtask

    task pulse_pm_play_pause;
        begin
            @(negedge clk);
            pm_play_pause = 1'b1;
            @(negedge clk);
            pm_play_pause = 1'b0;
            @(posedge clk);
            #1;
        end
    endtask

    task pulse_pm_note_done;
        begin
            @(negedge clk);
            pm_note_done = 1'b1;
            @(negedge clk);
            pm_note_done = 1'b0;
            @(posedge clk);
            #1;
        end
    endtask

    task pulse_pm_auto_song_changed;
        begin
            @(negedge clk);
            pm_auto_song_changed = 1'b1;
            @(negedge clk);
            pm_auto_song_changed = 1'b0;
            @(posedge clk);
            #1;
        end
    endtask

    task wait_for_scan_digit;
        input [2:0] logical_digit;
        begin
            @(posedge clk);
            #1;
            while (dut.u_sevenseg_scan.active_digit != logical_digit) begin
                @(posedge clk);
                #1;
            end
        end
    endtask

    task wait_for_order_scan_digit;
        input [2:0] logical_digit;
        begin
            @(posedge clk);
            #1;
            while (u_scan_order_check.active_digit != logical_digit) begin
                @(posedge clk);
                #1;
            end
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
        key_display_mode = 1'b1;
        pm_play_pause = 1'b0;
        pm_stop = 1'b0;
        pm_song_changed = 1'b0;
        pm_auto_song_changed = 1'b0;
        pm_note_done = 1'b0;
        pm_playback_mode = 2'd0;
        errors         = 0;
        beep_edges     = 0;

        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (10) @(posedge clk);

        pulse_pm_play_pause;
        if (!pm_playing) begin
            $display("ERROR: player mode check did not enter playing state");
            errors = errors + 1;
        end

        pulse_pm_note_done;
        if (pm_note_index != 8'd1) begin
            $display("ERROR: player mode check did not advance to note 1");
            errors = errors + 1;
        end

        pulse_pm_note_done;
        if (!pm_stopped || (pm_note_index != 8'd0)) begin
            $display("ERROR: stop playback mode did not stop at song end");
            errors = errors + 1;
        end

        pm_playback_mode = 2'd1;
        pulse_pm_play_pause;
        pulse_pm_note_done;
        pulse_pm_note_done;
        if (!pm_playing || (pm_note_index != 8'd0)) begin
            $display("ERROR: one-song loop mode did not keep playing at song end");
            errors = errors + 1;
        end

        pm_playback_mode = 2'd2;
        pulse_pm_auto_song_changed;
        if (!pm_playing || (pm_note_index != 8'd0)) begin
            $display("ERROR: all-song loop auto change did not keep player running");
            errors = errors + 1;
        end

        if ((dut.semitone_pitch != 8'd60) ||
            (dut.display_note_name != 3'd0) ||
            (dut.display_accidental != 2'd1) ||
            (dut.display_octave != 4'd4)) begin
            $display("ERROR: initial pitch did not decode as natural C4");
            errors = errors + 1;
        end

        if ((dut.led_row0 != 8'b0000_0001) ||
            (dut.led_row1 != 8'b0000_1000) ||
            (dut.led_row2[1:0] != 2'b00) ||
            (dut.led_row2[7:4] != 4'b0001)) begin
            $display("ERROR: LED panel did not show natural C4");
            errors = errors + 1;
        end

        if ((dut.beats_per_bar != 3'd4) ||
            (dut.first_beat_in_bar != 2'd0) ||
            (dut.beat_in_bar != 2'd0)) begin
            $display("ERROR: song beat metadata did not initialize as 4/4 first beat");
            errors = errors + 1;
        end

        if (dut.current_bpm != 8'd120) begin
            $display("ERROR: default BPM did not load from song metadata");
            errors = errors + 1;
        end

        if ((^seg_cs === 1'bx) || (^seg === 1'bx)) begin
            $display("ERROR: seven-segment scanner produced unknown outputs");
            errors = errors + 1;
        end

        if ((dut.sevenseg_glyphs != {5'd12, 5'd0, 5'd0, 5'd1, 5'd0, 5'd0, 5'd0, 5'd0}) ||
            (dut.sevenseg_decimal_points != 8'b0000_0100) ||
            (dut.sevenseg_blank != 8'b0000_0000)) begin
            $display("ERROR: seven-segment formatter did not show S001 and 00.00");
            errors = errors + 1;
        end

        press_display_mode;
        if ((dut.playback_display_mode != 2'd1) ||
            (dut.remaining_seconds != 16'd24) ||
            (dut.sevenseg_glyphs[19:0] != {5'd0, 5'd0, 5'd2, 5'd4}) ||
            (dut.sevenseg_decimal_points != 8'b0000_0100)) begin
            $display("ERROR: display mode did not show remaining time 00.24");
            errors = errors + 1;
        end

        press_display_mode;
        if ((dut.playback_display_mode != 2'd2) ||
            (dut.current_bar_number != 10'd1) ||
            (dut.current_beat_number != 3'd1) ||
            (dut.sevenseg_glyphs[19:0] != {5'd0, 5'd0, 5'd1, 5'd1}) ||
            (dut.sevenseg_decimal_points != 8'b0000_0010)) begin
            $display("ERROR: display mode did not show bar position 001.1");
            errors = errors + 1;
        end

        press_display_mode;
        if ((dut.playback_display_mode != 2'd0) ||
            (dut.sevenseg_glyphs[19:0] != {5'd0, 5'd0, 5'd0, 5'd0}) ||
            (dut.sevenseg_decimal_points != 8'b0000_0100)) begin
            $display("ERROR: display mode did not return to elapsed time 00.00");
            errors = errors + 1;
        end

        wait_for_scan_digit(3'd7);
        if ((seg_cs != 8'b1111_1110) || (seg[31:24] != 8'h6d)) begin
            $display("ERROR: seven-segment scanner did not map logical left digit to physical left digit cs=%b seg31_24=%h active=%0d physical=%0d glyph=%0d",
                     seg_cs, seg[31:24], dut.u_sevenseg_scan.active_digit,
                     dut.u_sevenseg_scan.physical_digit, dut.u_sevenseg_scan.active_glyph);
            errors = errors + 1;
        end

        wait_for_scan_digit(3'd0);
        if ((seg_cs != 8'b1011_1111) || (seg[7:0] != 8'h3f)) begin
            $display("ERROR: seven-segment scanner did not map logical right digit to physical right digit cs=%b seg7_0=%h active=%0d physical=%0d glyph=%0d",
                     seg_cs, seg[7:0], dut.u_sevenseg_scan.active_digit,
                     dut.u_sevenseg_scan.physical_digit, dut.u_sevenseg_scan.active_glyph);
            errors = errors + 1;
        end

        wait_for_order_scan_digit(3'd3);
        if ((scan_order_cs != 8'b1101_1111) || (scan_order_seg[15:8] != 8'h3f)) begin
            $display("ERROR: scan order did not put minute tens in the left minute digit");
            errors = errors + 1;
        end

        wait_for_order_scan_digit(3'd2);
        if ((scan_order_cs != 8'b1110_1111) || (scan_order_seg[15:8] != 8'h86)) begin
            $display("ERROR: scan order did not put minute ones in the right minute digit");
            errors = errors + 1;
        end

        wait_for_order_scan_digit(3'd1);
        if ((scan_order_cs != 8'b0111_1111) || (scan_order_seg[7:0] != 8'h06)) begin
            $display("ERROR: scan order did not put second tens in the left second digit");
            errors = errors + 1;
        end

        wait_for_order_scan_digit(3'd0);
        if ((scan_order_cs != 8'b1011_1111) || (scan_order_seg[7:0] != 8'h5b)) begin
            $display("ERROR: scan order did not put second ones in the right second digit");
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

        repeat (5200) @(posedge clk);
        if ((dut.beat_in_bar != 2'd1) || (dut.led_row2[7:4] != 4'b0010)) begin
            $display("ERROR: beat indicator did not advance to the second beat");
            errors = errors + 1;
        end

        if (dut.volume_level != 3'd7) begin
            $display("ERROR: reset volume is not maximum");
            errors = errors + 1;
        end

        press_volume_up;
        repeat (10) @(posedge clk);
        if ((dut.selected_song != 2'd1) || !dut.stopped || (dut.note_index != 0)) begin
            $display("ERROR: song parameter increment did not select and stop at song 1");
            errors = errors + 1;
        end

        press_volume_down;
        repeat (10) @(posedge clk);
        if ((dut.selected_song != 2'd0) || (dut.note_index != 0)) begin
            $display("ERROR: song parameter decrement did not wrap back to song 0");
            errors = errors + 1;
        end

        press_volume_down;
        repeat (10) @(posedge clk);
        if ((dut.selected_song != 2'd2) ||
            (dut.song_length != 8'd204) ||
            (dut.total_duration_16th != 16'd1044) ||
            (dut.current_bpm != 8'd200) ||
            (dut.beats_per_bar != 3'd3) ||
            (dut.key_tonic != 3'd6) ||
            (dut.semitone_pitch != 8'd75) ||
            (dut.display_note_name != 3'd1) ||
            (dut.display_accidental != 2'd2) ||
            (dut.display_octave != 4'd5) ||
            (dut.led_row2[7:4] != 4'b0010) ||
            (dut.sevenseg_glyphs[39:20] != {5'd12, 5'd0, 5'd0, 5'd3})) begin
            $display("ERROR: song parameter decrement did not select Haruhikage metadata");
            errors = errors + 1;
        end

        press_volume_up;
        repeat (10) @(posedge clk);
        if ((dut.selected_song != 2'd0) || (dut.current_bpm != 8'd120)) begin
            $display("ERROR: song parameter increment did not wrap back to song 0");
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

        if (dut.sevenseg_glyphs[39:20] != {5'd13, 5'd15, 5'd0, 5'd1}) begin
            $display("ERROR: seven-segment formatter did not show t+01");
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

        if (dut.sevenseg_glyphs[39:20] != {5'd14, 5'd1, 5'd2, 5'd1}) begin
            $display("ERROR: seven-segment formatter did not show b121");
            errors = errors + 1;
        end

        press_volume_down;
        repeat (10) @(posedge clk);
        if (dut.current_bpm != 8'd120) begin
            $display("ERROR: BPM decrement did not return to 120");
            errors = errors + 1;
        end

        press_next;
        if (dut.edit_mode != 2'd3) begin
            $display("ERROR: next key did not select volume edit mode");
            errors = errors + 1;
        end

        if (dut.sevenseg_glyphs[39:20] != {5'd16, 5'd0, 5'd0, 5'd7}) begin
            $display("ERROR: seven-segment formatter did not show U007");
            errors = errors + 1;
        end

        press_volume_down;
        repeat (10) @(posedge clk);
        if ((dut.volume_level != 3'd6) ||
            (dut.sevenseg_glyphs[39:20] != {5'd16, 5'd0, 5'd0, 5'd6})) begin
            $display("ERROR: volume decrement did not show U006");
            errors = errors + 1;
        end

        press_volume_up;
        repeat (10) @(posedge clk);
        if (dut.volume_level != 3'd7) begin
            $display("ERROR: volume increment did not return to maximum");
            errors = errors + 1;
        end

        press_next;
        if ((dut.edit_mode != 3'd4) ||
            (dut.playback_mode != 2'd0) ||
            (dut.sevenseg_glyphs[39:20] != {5'd17, 5'd11, 5'd12, 5'd13})) begin
            $display("ERROR: next key did not select stop playback mode");
            errors = errors + 1;
        end

        press_volume_up;
        repeat (10) @(posedge clk);
        if ((dut.playback_mode != 2'd1) ||
            (dut.sevenseg_glyphs[39:20] != {5'd17, 5'd11, 5'd1, 5'd19})) begin
            $display("ERROR: playback mode increment did not show P-1L");
            errors = errors + 1;
        end

        press_volume_up;
        repeat (10) @(posedge clk);
        if ((dut.playback_mode != 2'd2) ||
            (dut.sevenseg_glyphs[39:20] != {5'd17, 5'd11, 5'd18, 5'd19})) begin
            $display("ERROR: playback mode increment did not show P-AL");
            errors = errors + 1;
        end

        press_volume_down;
        repeat (10) @(posedge clk);
        press_volume_down;
        repeat (10) @(posedge clk);
        if (dut.playback_mode != 2'd0) begin
            $display("ERROR: playback mode decrement did not return to stop mode");
            errors = errors + 1;
        end

        press_next;
        if (dut.edit_mode != 3'd0) begin
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
