// TITLE: convert_scancode.sv
// PROJECT: Keyboard VLSI lab
// DESCRIPTION: Implement a shift register to convert serial to parallel
// A counter to flag when the valid code is shifted in

`timescale 1ns/1ps

module convert_scancode (
    input logic clk,
    input logic rst,
    input logic edge_found,
    input logic serial_data,
    output logic valid_scan_code,
    output logic [7:0] scan_code_out
    );

    // Frame = start + 8 data bits + parity + stop = 11 bits.
    // A 10-bit register is enough: by the time the 11th bit shifts in,
    // the start bit has been pushed out the far end.
    localparam int FRAME_BITS = 11;

    logic [9:0] shift_reg;
    logic [3:0] bit_count; // counts 0..FRAME_BITS-1

    always_ff @(posedge clk) begin : shift_and_count
        logic [9:0] next_reg;
        if (rst) begin
            shift_reg       <= 10'b0;
            bit_count       <= 4'd0;
            valid_scan_code <= 1'b0;
            scan_code_out   <= 8'b0;
        end else begin
            valid_scan_code <= 1'b0;
            if (edge_found) begin
                next_reg  = {serial_data, shift_reg[9:1]};
                shift_reg <= next_reg;
                if (bit_count == FRAME_BITS - 1) begin
                    bit_count       <= 4'd0;
                    valid_scan_code <= 1'b1;
                    scan_code_out   <= next_reg[7:0];
                end else begin
                    bit_count <= bit_count + 1'b1;
                end
            end
        end
    end

endmodule
