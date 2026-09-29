// TITLE: tb_binary_to_sg.sv
// PROJECT: Keyboard VLSI lab
// DESCRIPTION: Unit testbench for binary_to_sg (BCD -> 7-segment LUT)

`timescale 1ns/1ps

module tb_binary_to_sg();

    logic [3:0] binary_in;
    logic [7:0] sev_seg;
    int errors = 0;

    binary_to_sg dut (
        .binary_in(binary_in),
        .sev_seg(sev_seg)
        );

    task automatic check(input logic [3:0] val, input logic [7:0] expected);
        binary_in = val;
        #1;
        if (sev_seg !== expected) begin
            $display("FAIL: value %0d -> 0x%02x, expected 0x%02x",
                     val, sev_seg, expected);
            errors++;
        end
    endtask

    initial begin
        // {dp, g, f, e, d, c, b, a}, active-high
        check(4'd0, 8'b00111111);
        check(4'd1, 8'b00000110);
        check(4'd2, 8'b01011011);
        check(4'd3, 8'b01001111);
        check(4'd4, 8'b01100110);
        check(4'd5, 8'b01101101);
        check(4'd6, 8'b01111101);
        check(4'd7, 8'b00000111);
        check(4'd8, 8'b01111111);
        check(4'd9, 8'b01101111);

        // Anything else -> 'E'
        check(4'hA, 8'b01111001);
        check(4'hF, 8'b01111001);

        if (errors == 0) $display("tb_binary_to_sg: PASS");
        else             $display("tb_binary_to_sg: FAIL (%0d errors)", errors);
        $finish;
    end

endmodule
