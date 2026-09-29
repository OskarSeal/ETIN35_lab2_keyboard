// TITLE: tb_sync_keyboard.sv
// PROJECT: Keyboard VLSI lab
// DESCRIPTION: Unit testbench for sync_keyboard (input registering)

`timescale 1ns/1ps

module tb_sync_keyboard();

    logic clk = 0;
    logic kb_clk, kb_data;
    logic kb_clk_sync, kb_data_sync;
    int errors = 0;

    sync_keyboard dut (
        .clk(clk),
        .kb_clk(kb_clk),
        .kb_data(kb_data),
        .kb_clk_sync(kb_clk_sync),
        .kb_data_sync(kb_data_sync)
        );

    always #5 clk = ~clk;

    // Drive inputs on the negedge, then confirm the outputs match the
    // previous inputs one clock later (single-register delay).
    task automatic drive_and_check(input logic c, input logic d);
        @(negedge clk);
        kb_clk  = c;
        kb_data = d;
        @(posedge clk); // outputs capture c/d here
        #1;
        if (kb_clk_sync !== c || kb_data_sync !== d) begin
            $display("FAIL: drove clk=%b data=%b, got clk_sync=%b data_sync=%b",
                     c, d, kb_clk_sync, kb_data_sync);
            errors++;
        end
    endtask

    initial begin
        kb_clk  = 1;
        kb_data = 0;
        @(negedge clk);

        drive_and_check(1, 0);
        drive_and_check(0, 1);
        drive_and_check(1, 1);
        drive_and_check(0, 0);
        drive_and_check(1, 0);

        if (errors == 0) $display("tb_sync_keyboard: PASS");
        else             $display("tb_sync_keyboard: FAIL (%0d errors)", errors);
        $finish;
    end

endmodule
