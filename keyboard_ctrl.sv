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
    //Number of digits to display
    localparam int NUM_DIGITS = 4;
    // Counter size that controls the refresh rate of the display. Takes the top two bits to decide which display to show. 
    localparam int REFRESH_CNT_WIDTH = 16;

    localparam logic [7:0] BREAK_CODE = 8'hF0;

    // Most recently received scan codes
    logic [7:0] scan_code_hist [0:NUM_DIGITS-1];
    // The actual counter of the refresh rate. 
    logic [REFRESH_CNT_WIDTH-1:0] refresh_cnt;
    // The two digits selected for which display to show. 
    logic [1:0] digit_sel;

    // Makes sure that the break code has been received. 
    logic break_pending;

    logic [7:0] scan_code_hist_next [0:NUM_DIGITS-1];
    logic [REFRESH_CNT_WIDTH-1:0] refresh_cnt_next;
    logic break_pending_next;

    // Only a key *release* updates the display.
    always_comb begin : next_state
        scan_code_hist_next[0] = scan_code_hist[0];
        scan_code_hist_next[1] = scan_code_hist[1];
        scan_code_hist_next[2] = scan_code_hist[2];
        scan_code_hist_next[3] = scan_code_hist[3];
        break_pending_next     = break_pending;
        refresh_cnt_next       = refresh_cnt + 1'b1;

        if (valid_code) begin
            if (scan_code_in == BREAK_CODE) begin
                // Start of a break sequence; next byte is the released key
                break_pending_next = 1'b1;
            end else if (break_pending) begin
                // Byte following 0xF0 -> key released, show it now
                scan_code_hist_next[3] = scan_code_hist[2];
                scan_code_hist_next[2] = scan_code_hist[1];
                scan_code_hist_next[1] = scan_code_hist[0];
                scan_code_hist_next[0] = scan_code_in;
                break_pending_next     = 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin : registers
        if (rst) begin
            scan_code_hist[0] <= 8'h00;
            scan_code_hist[1] <= 8'h00;
            scan_code_hist[2] <= 8'h00;
            scan_code_hist[3] <= 8'h00;
            break_pending     <= 1'b0;
            refresh_cnt       <= '0;
        end else begin
            scan_code_hist[0] <= scan_code_hist_next[0];
            scan_code_hist[1] <= scan_code_hist_next[1];
            scan_code_hist[2] <= scan_code_hist_next[2];
            scan_code_hist[3] <= scan_code_hist_next[3];
            break_pending     <= break_pending_next;
            refresh_cnt       <= refresh_cnt_next;
        end
    end

    assign digit_sel = refresh_cnt[REFRESH_CNT_WIDTH-1:REFRESH_CNT_WIDTH-2];

    always_comb begin : outputs
        code_to_display = scan_code_hist[digit_sel];
        seg_en          = 4'b1111;
        seg_en[digit_sel] = 1'b0; // active-low: enable only the selected digit
    end

endmodule
