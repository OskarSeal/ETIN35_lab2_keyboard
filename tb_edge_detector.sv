// TITLE: tb_edge_detector.sv
// PROJECT: Keyboard VLSI lab
// DESCRIPTION: Unit testbench for edge_detector (falling-edge pulse on kb_clk_sync)

`timescale 1ns/1ps

module tb_edge_detector();

    logic clk = 0;
    logic rst;
    logic kb_clk_sync;
    logic edge_found;
    int errors = 0;

    edge_detector dut (
        .clk(clk),
        .rst(rst),
        .kb_clk_sync(kb_clk_sync),
        .edge_found(edge_found)
        );

    always #5 clk = ~clk;

    // Set kb_clk_sync on the negedge, let one posedge register the result,
    // then check the (registered) edge_found value.
    task automatic step(input logic level, input logic exp_edge);
        @(negedge clk);
        kb_clk_sync = level;
        @(posedge clk);
        #1;
        if (edge_found !== exp_edge) begin
            $display("FAIL: kb_clk_sync=%b -> edge_found=%b, expected %b",
                     level, edge_found, exp_edge);
            errors++;
        end
    endtask

    initial begin
        rst = 1;
        kb_clk_sync = 1; // PS/2 clock idles high
        @(negedge clk);
        @(negedge clk);
        rst = 0;

        step(1, 0); // stays high      -> no edge
        step(0, 1); // falling edge    -> pulse!
        step(0, 0); // stays low       -> no edge
        step(1, 0); // rising edge     -> ignored
        step(1, 0); // stays high      -> no edge
        step(0, 1); // falling edge    -> pulse!
        step(1, 0); // rising edge     -> ignored

        if (errors == 0) $display("tb_edge_detector: PASS");
        else             $display("tb_edge_detector: FAIL (%0d errors)", errors);
        $finish;
    end

endmodule
