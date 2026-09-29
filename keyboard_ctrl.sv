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

    // Break-code prefix: a key release is sent as 0xF0 followed by the
    // make code of the released key.
    localparam logic [7:0] BREAK_CODE = 8'hF0;

    // Most recently received scan codes, one per digit (index 0 = newest)
    logic [7:0] scan_code_hist [0:NUM_DIGITS-1];

    logic [REFRESH_CNT_WIDTH-1:0] refresh_cnt;
    logic [1:0] digit_sel;

    // High after a 0xF0 prefix has been seen, while we wait for the make
    // code that identifies the released key.
    logic break_pending;

    logic [7:0] scan_code_hist_next [0:NUM_DIGITS-1];
    logic [REFRESH_CNT_WIDTH-1:0] refresh_cnt_next;
    logic break_pending_next;

    // Only a key *release* updates the display. Each tap produces three
    // frames on the wire: make code (press), 0xF0 (break prefix), make
    // code (release). We ignore the initial make code, arm on 0xF0, then
    // store the byte that follows it.
    always_comb begin : next_state
        for (int i = 0; i < NUM_DIGITS; i++) begin
            scan_code_hist_next[i] = scan_code_hist[i];
        end
        break_pending_next = break_pending;
        refresh_cnt_next   = refresh_cnt + 1'b1;

        if (valid_code) begin
            if (scan_code_in == BREAK_CODE) begin
                // Start of a break sequence; next byte is the released key
                break_pending_next = 1'b1;
            end else if (break_pending) begin
                // Byte following 0xF0 -> key released, show it now
                for (int i = NUM_DIGITS - 1; i > 0; i--) begin
                    scan_code_hist_next[i] = scan_code_hist[i-1];
                end
                scan_code_hist_next[0] = scan_code_in;
                break_pending_next     = 1'b0;
            end
            // else: initial make code (press) -> ignore, wait for release
        end
    end

    always_ff @(posedge clk) begin : registers
        if (rst) begin
            for (int i = 0; i < NUM_DIGITS; i++) begin
                scan_code_hist[i] <= 8'h00;
            end
            break_pending <= 1'b0;
            refresh_cnt   <= '0;
        end else begin
            for (int i = 0; i < NUM_DIGITS; i++) begin
                scan_code_hist[i] <= scan_code_hist_next[i];
            end
            break_pending <= break_pending_next;
            refresh_cnt   <= refresh_cnt_next;
        end
    end

    assign digit_sel = refresh_cnt[REFRESH_CNT_WIDTH-1:REFRESH_CNT_WIDTH-2];

    always_comb begin : outputs
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
