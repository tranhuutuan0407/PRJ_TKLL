`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// ALU Control - RISC16 (BK-HK251)
//
// Inputs:
//   alu_op  (4-bit) : from Control Unit (alu_main)
//   funct3  (3-bit) : function field for R-type
//
// Output:
//   alu_sel (6-bit) : to ALU, selects exact operation
//
// R-type groups:
//   opcode 0000 (ALU0 unsigned): funct3 selects addu/subu/multu/divu/and/or/nor/xor
//   opcode 0001 (ALU1 signed)  : funct3 selects add/sub/mult/div/slt/seq/sltu/jr
//   opcode 0010 (SHIFT/ROTATE) : funct3 selects shl/shr/ror/rol
//
// I-type / other:
//   0011 ADDI  -> ADD
//   0100 SLTI  -> SLT signed with imm
//   0101 BNEQ  -> CMP_NEQ
//   0110 BGTZ  -> CMP_GTZ
//   1000 LH    -> ADDR_LHSH
//   1001 SH    -> ADDR_LHSH
//////////////////////////////////////////////////////////////////////////////////

module ALU_control(
    input  wire [2:0] funct3,
    input  wire [3:0] alu_op,
    output reg  [5:0] ALU_control
);

    // ========= Opcodes (alu_main) =========
    localparam OP_ALU0  = 4'b0000;
    localparam OP_ALU1  = 4'b0001;
    localparam OP_SHIFT = 4'b0010;
    localparam OP_ADDI  = 4'b0011;
    localparam OP_SLTI  = 4'b0100;
    localparam OP_BNEQ  = 4'b0101;
    localparam OP_BGTZ  = 4'b0110;
    localparam OP_LH    = 4'b1000;
    localparam OP_SH    = 4'b1001;

    // ========= ALU SEL encoding (6-bit) =========
    // Basic arithmetic/logical
    localparam SEL_ADD      = 6'd0;
    localparam SEL_SUB      = 6'd1;
    localparam SEL_AND      = 6'd2;
    localparam SEL_OR       = 6'd3;
    localparam SEL_NOR      = 6'd4;
    localparam SEL_XOR      = 6'd5;

    // Mult/Div (signed & unsigned) -> HI/LO outputs
    localparam SEL_MULT     = 6'd10;
    localparam SEL_DIV      = 6'd11;
    localparam SEL_MULTU    = 6'd12;
    localparam SEL_DIVU     = 6'd13;

    // Set-on conditions
    localparam SEL_SLT      = 6'd20;   // signed slt
    localparam SEL_SLTU     = 6'd21;   // unsigned sltu
    localparam SEL_SEQ      = 6'd22;   // seq

    // Shift / Rotate
    localparam SEL_SHL      = 6'd30;
    localparam SEL_SHR      = 6'd31;
    localparam SEL_ROR      = 6'd32;
    localparam SEL_ROL      = 6'd33;

    // Address calc for LH/SH per spec: (rs[15:1] + imm) << 1
    localparam SEL_ADDR_LHSH = 6'd40;

    // Branch comparisons
    localparam SEL_CMP_NEQ  = 6'd41;
    localparam SEL_CMP_GTZ  = 6'd42;

    // JR (handled in TOP next_pc; ALU can output don't-care)
    localparam SEL_JR_NOP   = 6'd63;

    always @(*) begin
        // default safe
        ALU_control = SEL_ADD;

        case (alu_op)

            // =========================
            // ALU0 (unsigned R-type)
            // funct3 mapping per spec:
            // 000 addu, 001 subu, 010 multu, 011 divu
            // 100 and,  101 or,   110 nor,   111 xor
            // =========================
            OP_ALU0: begin
                case (funct3)
                    3'b000: ALU_control = SEL_ADD;
                    3'b001: ALU_control = SEL_SUB;
                    3'b010: ALU_control = SEL_MULTU;
                    3'b011: ALU_control = SEL_DIVU;
                    3'b100: ALU_control = SEL_AND;
                    3'b101: ALU_control = SEL_OR;
                    3'b110: ALU_control = SEL_NOR;
                    3'b111: ALU_control = SEL_XOR;
                    default: ALU_control = SEL_ADD;
                endcase
            end

            // =========================
            // ALU1 (signed R-type + jr)
            // funct3 mapping per spec:
            // 000 add, 001 sub, 010 mult, 011 div
            // 100 slt, 101 seq, 110 sltu, 111 jr
            // =========================
            OP_ALU1: begin
                case (funct3)
                    3'b000: ALU_control = SEL_ADD;
                    3'b001: ALU_control = SEL_SUB;
                    3'b010: ALU_control = SEL_MULT;
                    3'b011: ALU_control = SEL_DIV;
                    3'b100: ALU_control = SEL_SLT;
                    3'b101: ALU_control = SEL_SEQ;
                    3'b110: ALU_control = SEL_SLTU;
                    3'b111: ALU_control = SEL_JR_NOP; // jr handled in PC logic
                    default: ALU_control = SEL_ADD;
                endcase
            end

            // =========================
            // SHIFT/ROTATE (R-type)
            // funct3 mapping per spec:
            // 000 shl, 001 shr, 010 ror, 011 rol
            // =========================
            OP_SHIFT: begin
                case (funct3)
                    3'b000: ALU_control = SEL_SHL;
                    3'b001: ALU_control = SEL_SHR;
                    3'b010: ALU_control = SEL_ROR;
                    3'b011: ALU_control = SEL_ROL;
                    default: ALU_control = SEL_SHL;
                endcase
            end

            // =========================
            // I-type arithmetic
            // =========================
            OP_ADDI: begin
                ALU_control = SEL_ADD;
            end

            OP_SLTI: begin
                ALU_control = SEL_SLT;  // signed compare with imm
            end

            // =========================
            // Branch compare ops
            // =========================
            OP_BNEQ: begin
                ALU_control = SEL_CMP_NEQ;
            end

            OP_BGTZ: begin
                ALU_control = SEL_CMP_GTZ;
            end

            // =========================
            // Memory address calculation
            // =========================
            OP_LH, OP_SH: begin
                ALU_control = SEL_ADDR_LHSH;
            end

            default: begin
                ALU_control = SEL_ADD;
            end
        endcase
    end

endmodule
