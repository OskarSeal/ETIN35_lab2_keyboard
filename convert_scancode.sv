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
    // 0 = idle, waiting for a start bit; 1..FRAME_BITS-1 = mid-frame
    logic [3:0] bit_count;

    logic [9:0] shift_reg_next;
    logic [3:0] bit_count_next;
    logic       valid_scan_code_next;
    logic [7:0] scan_code_out_next;

    logic [9:0] shifted;

    always_comb begin : next_state
        shifted = {serial_data, shift_reg[9:1]};

        shift_reg_next       = shift_reg;
        bit_count_next       = bit_count;
        valid_scan_code_next = 1'b0;
        scan_code_out_next   = scan_code_out;

        if (edge_found) begin
            if (bit_count == 4'd0) begin
                // A frame only really begins on a low start bit. Ignoring
                // other edges keeps us aligned to real byte boundaries.
                if (serial_data == 1'b0) begin
                    shift_reg_next = 10'b0;
                    bit_count_next = 4'd1;
                end
            end else begin
                shift_reg_next = shifted;
                if (bit_count == FRAME_BITS - 1) begin
                    // This edge carries the stop bit, which must be high.
                    // If it isn't, the frame is misaligned or corrupt, so
                    // drop it rather than trusting the data.
                    bit_count_next = 4'd0; // back to idle
                    if (serial_data == 1'b1) begin
                        valid_scan_code_next = 1'b1;
                        scan_code_out_next   = shifted[7:0];
                    end
                end else begin
                    bit_count_next = bit_count + 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk) begin : registers
        if (rst) begin
            shift_reg       <= 10'b0;
            bit_count       <= 4'd0;
            valid_scan_code <= 1'b0;
            scan_code_out   <= 8'b0;
        end else begin
            shift_reg       <= shift_reg_next;
            bit_count       <= bit_count_next;
            valid_scan_code <= valid_scan_code_next;
            scan_code_out   <= scan_code_out_next;
        end
    end

endmodule
