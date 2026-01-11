`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Program Counter - RISC16
// - reset -> PC = 0x0000
// - hold_hlt = 1 -> PC holds value
// - else PC updates to pc_in every posedge clk
//////////////////////////////////////////////////////////////////////////////////

module program_counter(
    input  wire        clk,
    input  wire        reset,
    input  wire [15:0]  pc_in,
    input  wire        hold_hlt,
    output reg  [15:0]  pc_out
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        pc_out <= 16'h0000;
    end
    else if (hold_hlt) begin
        pc_out <= pc_out;       // hold PC
    end
    else begin
        pc_out <= pc_in;        // normal update
    end
end

endmodule


