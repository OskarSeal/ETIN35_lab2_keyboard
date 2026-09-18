// TITLE: edge_detector.sv
// PROJECT: Keyboard VLSI lab
// DESCRIPTION: Make sure not to use posedge/negedge on any other signal than clk

`timescale 1ns/1ps

module edge_detector (
    input logic clk,
    input logic rst,
    input logic kb_clk_sync,
    output logic edge_found
    );

    logic kb_clk_prev;

    always_ff @(posedge clk) begin
        if (rst) begin
            kb_clk_prev <= 1'b1; // PS/2 clock idles high
            edge_found  <= 1'b0;
        end else begin
            kb_clk_prev <= kb_clk_sync;
            edge_found  <= kb_clk_prev & ~kb_clk_sync;
        end
    end

endmodule
