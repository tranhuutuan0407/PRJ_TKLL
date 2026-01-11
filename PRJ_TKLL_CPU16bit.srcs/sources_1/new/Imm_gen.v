`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Immediate Generator - RISC16
//
// imm_type encodings (must match Control Unit):
// 000: IMM_NONE  -> 0
// 001: IMM_SEXT6 -> sign-extend imm6
// 010: IMM_BR    -> sign-extend imm6 then << 1  (PC offset = i*2)
//
//////////////////////////////////////////////////////////////////////////////////

module Imm_gen(
    input  wire [15:0] instruction,
    input  wire [2:0]  imm_type,
    output reg  [15:0] imm_out
);

    // imm6 is lower 6 bits of instruction in I-type format
    wire [5:0] imm6 = instruction[5:0];

    // sign-extend imm6 -> 16-bit
    wire [15:0] sext6 = {{10{imm6[5]}}, imm6};

    // local immtype constants
    localparam IMM_NONE  = 3'b000;
    localparam IMM_SEXT6 = 3'b001;
    localparam IMM_BR    = 3'b010;

    always @(*) begin
        case (imm_type)
            IMM_SEXT6: imm_out = sext6;          // addi/slti/lh/sh
            IMM_BR:    imm_out = sext6 << 1;     // bneq/bgtz (i*2)
            default:   imm_out = 16'h0000;
        endcase
    end

endmodule
