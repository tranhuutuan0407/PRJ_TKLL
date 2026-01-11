`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// ALU - RISC16 (BK-HK251)
//
// Inputs:
//   A, B      : 16-bit operands (A usually rs, B is rt or imm)
//   alu_sel   : 6-bit from ALU_control
//
// Outputs:
//   ALU_out   : main 16-bit output
//   hi_out    : high 16 bits (mult/div result)
//   lo_out    : low  16 bits (mult/div result)
//   cmp       : compare flag for branch (BNEQ/BGTZ)
//
// Notes:
// - Shift amount uses A[3:0] (per spec: [$rs]3,0)
// - LH/SH address per spec: (rs[15:1] + imm) << 1
//////////////////////////////////////////////////////////////////////////////////
module ALU(
    input  wire [15:0] A,
    input  wire [15:0] B,
    input  wire [5:0]  alu_sel,
    output reg  [15:0] ALU_out,
    output reg  [15:0] hi_out,
    output reg  [15:0] lo_out,
    output reg         cmp
);
    // ========= alu_sel constants (must match ALU_control) =========
    localparam SEL_ADD       = 6'd0;
    localparam SEL_SUB       = 6'd1;
    localparam SEL_AND       = 6'd2;
    localparam SEL_OR        = 6'd3;
    localparam SEL_NOR       = 6'd4;
    localparam SEL_XOR       = 6'd5;
    localparam SEL_MULT      = 6'd10;
    localparam SEL_DIV       = 6'd11;
    localparam SEL_MULTU     = 6'd12;
    localparam SEL_DIVU      = 6'd13;
    localparam SEL_SLT       = 6'd20;
    localparam SEL_SLTU      = 6'd21;
    localparam SEL_SEQ       = 6'd22;
    localparam SEL_SHL       = 6'd30;
    localparam SEL_SHR       = 6'd31;
    localparam SEL_ROR       = 6'd32;
    localparam SEL_ROL       = 6'd33;
    localparam SEL_ADDR_LHSH = 6'd40;
    localparam SEL_CMP_NEQ   = 6'd41;
    localparam SEL_CMP_GTZ   = 6'd42;
    // signed versions for signed ops
    wire signed [15:0] As = A;
    wire signed [15:0] Bs = B;
    // shift amount from A[3:0] (spec: [$rs]3,0)
    wire [3:0] shamt = A[3:0];
    // rotate helpers
    wire [15:0] ror_val = (shamt==0) ? B : ((B >> shamt) | (B << (16 - shamt)));
    wire [15:0] rol_val = (shamt==0) ? B : ((B << shamt) | (B >> (16 - shamt)));
    // mult products
    wire signed [31:0] mult_s  = As * Bs;
    wire        [31:0] mult_u  = A  * B;
    // div results (protect divide by zero)
    wire signed [15:0] div_q_s = (B != 0) ? (As / Bs) : 16'h0000;
    wire signed [15:0] div_r_s = (B != 0) ? (As % Bs) : 16'h0000;
    wire [15:0] div_q_u = (B != 0) ? (A / B) : 16'h0000;
    wire [15:0] div_r_u = (B != 0) ? (A % B) : 16'h0000;
    always @(*) begin
        // defaults
        ALU_out = 16'h0000;
        hi_out  = 16'h0000;
        lo_out  = 16'h0000;
        cmp     = 1'b0;
        case (alu_sel)
            // ================= Basic arithmetic/logic =================
            SEL_ADD:  ALU_out = A + B;
            SEL_SUB:  ALU_out = A - B;
            SEL_AND:  ALU_out = A & B;
            SEL_OR:   ALU_out = A | B;
            SEL_NOR:  ALU_out = ~(A | B);
            SEL_XOR:  ALU_out = A ^ B;
            // ================= Set / Compare =================
            SEL_SLT: begin
                ALU_out = (As < Bs) ? 16'h0001 : 16'h0000;
            end
            SEL_SLTU: begin
                ALU_out = (A < B) ? 16'h0001 : 16'h0000;
            end
            SEL_SEQ: begin
                ALU_out = (A == B) ? 16'h0001 : 16'h0000;
            end
            // ================= Shift / Rotate (B is the data) =================
            SEL_SHL: begin
                ALU_out = B << shamt;
            end
            SEL_SHR: begin
                ALU_out = B >> shamt;
            end
            SEL_ROR: begin
                // if shamt==0, ror_val == B (safe)
                ALU_out = ror_val;
            end
            SEL_ROL: begin
                ALU_out = rol_val;
            end
            // ================= Mult / Div (HI/LO results) =================
            SEL_MULT: begin
                hi_out = mult_s[31:16];
                lo_out = mult_s[15:0];
                ALU_out = mult_s[15:0]; // deterministic main output
            end
            SEL_MULTU: begin
                hi_out = mult_u[31:16];
                lo_out = mult_u[15:0];
                ALU_out = mult_u[15:0]; // deterministic main output
            end
            SEL_DIV: begin
                // LO = quotient, HI = remainder (MIPS-like)
                lo_out = div_q_s;
                hi_out = div_r_s;
                ALU_out = div_q_s; // deterministic main output
            end
            SEL_DIVU: begin
                lo_out = div_q_u;
                hi_out = div_r_u;
                ALU_out = div_q_u; // deterministic main output
            end
            // ================= Branch compares (cmp output) =================
            SEL_CMP_NEQ: begin
                cmp = (A != B);
            end
            SEL_CMP_GTZ: begin
                cmp = (As > 0);
            end
            // ================= LH/SH address per spec =================
            // start = (rs[15:1] + imm) << 1
            SEL_ADDR_LHSH: begin
                ALU_out = ( {A[15], A[15:1]} + B ) << 1; // keep MSB; (A>>1) with sign bit preserved
            end
            default: begin
                // keep defaults
                ALU_out = 16'h0000;
            end
        endcase
    end
endmodule
