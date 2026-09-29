// TITLE: tb_convert_scancode.sv
// PROJECT: Keyboard VLSI lab
// DESCRIPTION: Unit testbench for convert_scancode (serial->parallel + framing)

`timescale 1ns/1ps

module tb_convert_scancode();

    logic clk = 0;
    logic rst;
    logic edge_found;
    logic serial_data;
    logic valid_scan_code;
    logic [7:0] scan_code_out;
    int errors = 0;

    convert_scancode dut (
        .clk(clk),
        .rst(rst),
        .edge_found(edge_found),
        .serial_data(serial_data),
        .valid_scan_code(valid_scan_code),
        .scan_code_out(scan_code_out)
        );

    always #5 clk = ~clk;

    // Present one PS/2 bit accompanied by a single-cycle edge_found pulse,
    // mimicking what edge_detector produces per keyboard-clock falling edge.
    task automatic send_bit(input logic b);
        @(negedge clk);
        serial_data = b;
        edge_found  = 1'b1;
        @(negedge clk);
        edge_found  = 1'b0;
    endtask

    // Full 11-bit PS/2 frame: start(0) + 8 data (LSB first) + odd parity + stop(1)
    task automatic send_frame(input logic [7:0] code);
        logic parity;
        parity = ~(^code); // odd parity (ignored by DUT, sent for realism)
        send_bit(1'b0);                       // start
        for (int i = 0; i < 8; i++)
            send_bit(code[i]);                // data, LSB first
        send_bit(parity);                     // parity
        send_bit(1'b1);                       // stop
    endtask

    // After a frame, valid_scan_code should be high for exactly this cycle
    task automatic check_frame(input logic [7:0] code);
        send_frame(code);
        // We are at a negedge with edge_found=0; valid was asserted on the
        // 11th bit's posedge and is still high here.
        if (valid_scan_code !== 1'b1) begin
            $display("FAIL: valid_scan_code not asserted after frame 0x%02x", code);
            errors++;
        end
        if (scan_code_out !== code) begin
            $display("FAIL: scan_code_out=0x%02x, expected 0x%02x", scan_code_out, code);
            errors++;
        end
        // Next cycle it must self-clear
        @(posedge clk);
        #1;
        if (valid_scan_code !== 1'b0) begin
            $display("FAIL: valid_scan_code did not clear after frame 0x%02x", code);
            errors++;
        end
    endtask

    initial begin
        rst = 1;
        edge_found = 0;
        serial_data = 0;
        @(negedge clk);
        @(negedge clk);
        rst = 0;
        @(negedge clk);

        check_frame(8'h16); // '1'
        check_frame(8'hF0); // break prefix
        check_frame(8'h45); // '0'
        check_frame(8'hAA); // arbitrary pattern

        if (errors == 0) $display("tb_convert_scancode: PASS");
        else             $display("tb_convert_scancode: FAIL (%0d errors)", errors);
        $finish;
    end

endmodule
