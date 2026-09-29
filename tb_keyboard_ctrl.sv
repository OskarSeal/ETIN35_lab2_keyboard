// TITLE: tb_keyboard_ctrl.sv
// PROJECT: Keyboard VLSI lab
// DESCRIPTION: Unit testbench for keyboard_ctrl. Verifies that the display
//              updates only on key RELEASE (0xF0-prefixed make code), and
//              that the initial make code and the 0xF0 prefix are ignored.

`timescale 1ns/1ps

module tb_keyboard_ctrl();

    logic clk = 0;
    logic rst;
    logic valid_code;
    logic [7:0] scan_code_in;
    logic [7:0] code_to_display;
    logic [3:0] seg_en;
    int errors = 0;

    keyboard_ctrl dut (
        .clk(clk),
        .rst(rst),
        .valid_code(valid_code),
        .scan_code_in(scan_code_in),
        .code_to_display(code_to_display),
        .seg_en(seg_en)
        );

    always #5 clk = ~clk;

    // Pulse valid_code for one cycle with the given byte, as convert_scancode
    // would when a full frame arrives.
    task automatic send_code(input logic [7:0] c);
        @(negedge clk);
        scan_code_in = c;
        valid_code   = 1'b1;
        @(negedge clk);
        valid_code   = 1'b0;
    endtask

    // The refresh counter starts at 0, so digit_sel = 0 (and only digit 0 is
    // enabled) for the first ~16k cycles -- well beyond this short test.
    // That lets us read scan_code_hist[0] directly off code_to_display.
    task automatic check_display(input logic [7:0] expected, input string msg);
        #1;
        if (code_to_display !== expected) begin
            $display("FAIL (%s): code_to_display=0x%02x, expected 0x%02x",
                     msg, code_to_display, expected);
            errors++;
        end
        if (seg_en !== 4'b1110) begin
            $display("FAIL (%s): seg_en=%b, expected 1110 (digit 0 active)",
                     msg, seg_en);
            errors++;
        end
    endtask

    initial begin
        rst = 1;
        valid_code = 0;
        scan_code_in = 8'h00;
        @(negedge clk);
        @(negedge clk);
        rst = 0;
        @(negedge clk);

        // Nothing pressed yet -> display blank (0x00)
        check_display(8'h00, "after reset");

        // ---- Tap key '1' (0x16): make, then break (F0 16) ----
        send_code(8'h16);              // press -> must be ignored
        check_display(8'h00, "make 0x16 ignored");

        send_code(8'hF0);              // break prefix -> arm, no display change
        check_display(8'h00, "0xF0 prefix ignored");

        send_code(8'h16);              // release -> NOW show it
        check_display(8'h16, "release 0x16 shown");

        // ---- Tap key '2' (0x1E) ----
        send_code(8'h1E);              // press -> ignored, still shows 0x16
        check_display(8'h16, "make 0x1E ignored");

        send_code(8'hF0);
        check_display(8'h16, "0xF0 prefix ignored (2)");

        send_code(8'h1E);              // release -> newest digit becomes 0x1E
        check_display(8'h1E, "release 0x1E shown");

        // ---- A stray make with no release must not update ----
        send_code(8'h26);              // press '3', never released
        check_display(8'h1E, "stray make 0x26 ignored");

        if (errors == 0) $display("tb_keyboard_ctrl: PASS");
        else             $display("tb_keyboard_ctrl: FAIL (%0d errors)", errors);
        $finish;
    end

endmodule
