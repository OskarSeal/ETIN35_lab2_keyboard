// TITLE: tb_convert_to_binary.sv
// PROJECT: Keyboard VLSI lab
// DESCRIPTION: Unit testbench for convert_to_binary (scan code -> BCD LUT)

`timescale 1ns/1ps

module tb_convert_to_binary();

    logic [7:0] scan_code_in;
    logic [3:0] binary_out;
    int errors = 0;

    convert_to_binary dut (
        .scan_code_in(scan_code_in),
        .binary_out(binary_out)
        );

    // Apply a code, wait for combinational settle, compare
    task automatic check(input logic [7:0] code, input logic [3:0] expected);
        scan_code_in = code;
        #1;
        if (binary_out !== expected) begin
            $display("FAIL: scan_code 0x%02x -> %0d, expected %0d",
                     code, binary_out, expected);
            errors++;
        end
    endtask

    initial begin
        // Digit make codes (PS/2 Set-2)
        check(8'h45, 4'd0);
        check(8'h16, 4'd1);
        check(8'h1E, 4'd2);
        check(8'h26, 4'd3);
        check(8'h25, 4'd4);
        check(8'h2E, 4'd5);
        check(8'h36, 4'd6);
        check(8'h3D, 4'd7);
        check(8'h3E, 4'd8);
        check(8'h46, 4'd9);

        // Non-digit keys -> 0xF ('E')
        check(8'h00, 4'hF);
        check(8'hF0, 4'hF); // break prefix
        check(8'h5A, 4'hF); // Enter
        check(8'h29, 4'hF); // Space

        if (errors == 0) $display("tb_convert_to_binary: PASS");
        else             $display("tb_convert_to_binary: FAIL (%0d errors)", errors);
        $finish;
    end

endmodule
