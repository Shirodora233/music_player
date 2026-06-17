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

    integer errors;
    integer beep_edges;
    reg [5:0] paused_index;

    music_top #(
        .CLK_FREQ_HZ(100_000),
        .BEAT_MS(10),
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
        .led(led)
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

        press_volume_down;
        press_volume_down;
        press_volume_down;
        press_volume_down;
        repeat (10) @(posedge clk);
        if ((dut.volume_level != 3'd0) || (beep !== 1'b0) || (dut.status_led[7:4] != 4'b0000)) begin
            $display("ERROR: volume down did not reach mute");
            errors = errors + 1;
        end

        beep_edges = 0;
        press_volume_up;
        repeat (500) @(posedge clk);
        if ((dut.volume_level != 3'd1) || (beep_edges == 0) || (dut.status_led[7:4] != 4'b0001)) begin
            $display("ERROR: volume up did not leave mute at level 1");
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
        press_next;
        if ((dut.selected_song != 1'b1) || (dut.note_index != 0)) begin
            $display("ERROR: next key did not select and restart song 1");
            errors = errors + 1;
        end

        press_stop;
        if (!dut.stopped || (dut.note_index != 0) || (beep !== 1'b0)) begin
            $display("ERROR: stop key did not reset playback");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("PASS: music player control, tone, and volume tests completed");
        else
            $display("FAIL: %0d test(s) failed", errors);

        $finish;
    end

endmodule
