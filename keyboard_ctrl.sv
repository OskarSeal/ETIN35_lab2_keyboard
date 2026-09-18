// TITLE: keyboard_ctrl.sv
// PROJECT: Keyboard VLSI lab
// DESCRIPTION: Controller to handle the scan codes

`timescale 1ns/1ps

module keyboard_ctrl (
    input logic clk,
    input logic rst,
    input logic valid_code,
    input logic [7:0] scan_code_in,
    output logic [7:0] code_to_display,
    output logic [3:0] seg_en
    );

    localparam int NUM_DIGITS = 4;

    // Top 2 bits of this counter select the active digit. Only one
    // seven-segment display can be driven at a time (code_to_display/num
    // is shared by all four), so the digits are refreshed in round-robin
    // fast enough that persistence of vision makes them look simultaneous.
    localparam int REFRESH_CNT_WIDTH = 16;

    // Most recently received scan codes, one per digit (index 0 = newest)
    logic [7:0] scan_code_hist [0:NUM_DIGITS-1];

    logic [REFRESH_CNT_WIDTH-1:0] refresh_cnt;
    logic [1:0] digit_sel;

    always_ff @(posedge clk) begin : history
        if (rst) begin
            for (int i = 0; i < NUM_DIGITS; i++) begin
                scan_code_hist[i] <= 8'h00;
            end
        end else if (valid_code) begin
            for (int i = NUM_DIGITS - 1; i > 0; i--) begin
                scan_code_hist[i] <= scan_code_hist[i-1];
            end
            scan_code_hist[0] <= scan_code_in;
        end
    end

    always_ff @(posedge clk) begin : refresh
        if (rst) begin
            refresh_cnt <= '0;
        end else begin
            refresh_cnt <= refresh_cnt + 1'b1;
        end
    end

    assign digit_sel = refresh_cnt[REFRESH_CNT_WIDTH-1:REFRESH_CNT_WIDTH-2];

    always_comb begin
        if (rst) begin
            code_to_display = 8'h00;
            seg_en          = 4'b1111;
        end else begin
            code_to_display = scan_code_hist[digit_sel];
            seg_en          = 4'b1111;
            seg_en[digit_sel] = 1'b0; // active-low: enable only the selected digit
        end
    end

endmodule
