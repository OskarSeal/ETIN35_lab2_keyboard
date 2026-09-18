// TITLE: binary_to_sgd.sv
// PROJECT: Keyboard VLSI lab
// DESCRIPTION: Simple look-up table

`timescale 1ns/1ps

module binary_to_sg (
    input logic [3:0] binary_in,
    output logic [7:0] sev_seg
    );

    // Active-high segments, bit order {dp, g, f, e, d, c, b, a}
    always_comb begin
        case (binary_in)
            4'd0:    sev_seg = 8'b00111111;
            4'd1:    sev_seg = 8'b00000110;
            4'd2:    sev_seg = 8'b01011011;
            4'd3:    sev_seg = 8'b01001111;
            4'd4:    sev_seg = 8'b01100110;
            4'd5:    sev_seg = 8'b01101101;
            4'd6:    sev_seg = 8'b01111101;
            4'd7:    sev_seg = 8'b00000111;
            4'd8:    sev_seg = 8'b01111111;
            4'd9:    sev_seg = 8'b01101111;
            default: sev_seg = 8'b01111001; // 'E'
        endcase
    end

endmodule
