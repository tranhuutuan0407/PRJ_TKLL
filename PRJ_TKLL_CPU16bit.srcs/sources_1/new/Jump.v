`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Jump Target Generator - RISC16
// Spec: PC <- PC[15:13] || (addr << 1)
// - addr is 12-bit field in instruction[11:0]
// - shift-left-1 because instructions are 16-bit word aligned
//////////////////////////////////////////////////////////////////////////////////

module Jump(
    input  wire [15:0] pc,            // recommend using pc_plus2
    input  wire [15:0] instruction,    // full 16-bit instruction
    output wire [15:0] jump_target
);

wire [11:0] addr = instruction[11:0];

// { pc[15:13], addr, 1'b0 } = pc_high(3 bits) + addr(12 bits) + alignment bit
assign jump_target = { pc[15:13], addr, 1'b0 };

endmodule
