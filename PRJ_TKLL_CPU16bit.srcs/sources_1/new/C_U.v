`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Control Unit - RISC16 (MIPS-like) per BK-HK251 spec
//
// Outputs:
// - WB select: wb_sel = 00(ALU), 01(MEM), 10(SPECIAL)
// - next_pc priority handled in TOP: JR > JUMP > BRANCH > PC+2
// - JR is ALU1 funct3=111
// - mult/div (signed/unsigned) write HI/LO (no GPR write)
// - MFSR writes to rd from special register
// - MTSR writes special register from rt
//////////////////////////////////////////////////////////////////////////////////

module C_U(
    input  [3:0] opcode,
    input  [2:0] funct3,

    // core control
    output reg       reg_write,
    output reg       alu_src,        // 0: rt, 1: imm
    output reg       reg_dst,        // 0: rt, 1: rd
    output reg       mem_read,
    output reg       mem_write,
    output reg       branch_en,
    output reg       jump_en,
    output reg       hold_hlt,

    // WB select
    output reg [1:0] wb_sel,         // 00 ALU, 01 MEM, 10 SPECIAL

    // imm
    output reg [2:0] immtype,        // IMM_NONE, IMM_SEXT6, IMM_BR

    // ALU main class (forward to ALU_control)
    output reg [3:0] alu_main,

    // branch type (optional for debug / datapath)
    output reg       branch_type,    // 0: BNEQ, 1: BGTZ

    // JR support
    output reg       jr_en,          // jr $rs

    // special register access
    output reg [2:0] mfsr_sel,       // select ZERO/PC/RA/AT/HI/LO

    // MTSR write enables
    output reg       mtra, mtat, mthi, mtlo,

    // HI/LO write enable from ALU (for mult/div)
    output reg       hi_lo_from_alu
);

    // =========================
    // Opcodes per spec
    // =========================
    localparam OP_ALU0  = 4'b0000;   // unsigned R-type
    localparam OP_ALU1  = 4'b0001;   // signed R-type (+ jr)
    localparam OP_SHIFT = 4'b0010;   // shift/rotate R-type
    localparam OP_ADDI  = 4'b0011;   // addi
    localparam OP_SLTI  = 4'b0100;   // slti
    localparam OP_BNEQ  = 4'b0101;   // bneq
    localparam OP_BGTZ  = 4'b0110;   // bgtz
    localparam OP_JUMP  = 4'b0111;   // j
    localparam OP_LH    = 4'b1000;   // lh
    localparam OP_SH    = 4'b1001;   // sh
    localparam OP_MFSR  = 4'b1010;   // move from special reg
    localparam OP_MTSR  = 4'b1011;   // move to special reg
    localparam OP_HLT   = 4'b1111;   // halt

    // =========================
    // WB select encoding
    // =========================
    localparam WB_ALU     = 2'b00;
    localparam WB_MEM     = 2'b01;
    localparam WB_SPECIAL = 2'b10;

    // =========================
    // Immediate type encoding
    // =========================
    localparam IMM_NONE  = 3'b000;
    localparam IMM_SEXT6 = 3'b001;   // sign-extend imm6
    localparam IMM_BR    = 3'b010;   // sign-extend imm6 then <<1

    always @(*) begin
        // -------------------------
        // Defaults
        // -------------------------
        reg_write      = 1'b0;
        alu_src        = 1'b0;
        reg_dst        = 1'b0;
        mem_read       = 1'b0;
        mem_write      = 1'b0;
        branch_en      = 1'b0;
        jump_en        = 1'b0;
        hold_hlt       = 1'b0;

        wb_sel         = WB_ALU;
        immtype        = IMM_NONE;
        alu_main       = 4'b0000;

        branch_type    = 1'b0;

        jr_en          = 1'b0;

        mfsr_sel       = 3'b000;
        mtra           = 1'b0;
        mtat           = 1'b0;
        mthi           = 1'b0;
        mtlo           = 1'b0;

        hi_lo_from_alu = 1'b0;

        // -------------------------
        // Decode by opcode
        // -------------------------
        case (opcode)

            // ====== ALU0 (unsigned R-type) ======
            OP_ALU0: begin
                alu_main  = OP_ALU0;
                reg_write = 1'b1;
                reg_dst   = 1'b1;
                wb_sel    = WB_ALU;

                // multu/divu: funct3 010/011 => HI/LO
                if (funct3 == 3'b010 || funct3 == 3'b011) begin
                    hi_lo_from_alu = 1'b1;
                    reg_write      = 1'b0;
                end
            end

            // ====== ALU1 (signed R-type + jr) ======
            OP_ALU1: begin
                alu_main = OP_ALU1;

                // jr $rs: funct3 = 111 (per spec)
                if (funct3 == 3'b111) begin
                    jr_en     = 1'b1;
                    reg_write = 1'b0;
                end
                else begin
                    reg_write = 1'b1;
                    reg_dst   = 1'b1;
                    wb_sel    = WB_ALU;

                    // mult/div: funct3 010/011 => HI/LO
                    if (funct3 == 3'b010 || funct3 == 3'b011) begin
                        hi_lo_from_alu = 1'b1;
                        reg_write      = 1'b0;
                    end
                end
            end

            // ====== SHIFT/ROTATE (R-type) ======
            OP_SHIFT: begin
                alu_main  = OP_SHIFT;
                reg_write = 1'b1;
                reg_dst   = 1'b1;
                wb_sel    = WB_ALU;
            end

            // ====== ADDI ======
            OP_ADDI: begin
                alu_main  = OP_ADDI;
                alu_src   = 1'b1;
                immtype   = IMM_SEXT6;

                reg_write = 1'b1;
                reg_dst   = 1'b0;
                wb_sel    = WB_ALU;
            end

            // ====== SLTI ======
            OP_SLTI: begin
                alu_main  = OP_SLTI;
                alu_src   = 1'b1;
                immtype   = IMM_SEXT6;

                reg_write = 1'b1;
                reg_dst   = 1'b0;
                wb_sel    = WB_ALU;
            end

            // ====== BNEQ ======
            OP_BNEQ: begin
                alu_main    = OP_BNEQ;
                branch_en   = 1'b1;
                branch_type = 1'b0;   // BNEQ
                immtype     = IMM_BR;
            end

            // ====== BGTZ ======
            OP_BGTZ: begin
                alu_main    = OP_BGTZ;
                branch_en   = 1'b1;
                branch_type = 1'b1;   // BGTZ
                immtype     = IMM_BR;
            end

            // ====== JUMP ======
            OP_JUMP: begin
                jump_en = 1'b1;
            end

            // ====== LH ======
            OP_LH: begin
                alu_main  = OP_LH;     // ALU must compute address per spec
                alu_src   = 1'b1;
                immtype   = IMM_SEXT6;

                mem_read  = 1'b1;
                reg_write = 1'b1;
                reg_dst   = 1'b0;      // rt
                wb_sel    = WB_MEM;
            end

            // ====== SH ======
            OP_SH: begin
                alu_main   = OP_SH;
                alu_src    = 1'b1;
                immtype    = IMM_SEXT6;

                mem_write  = 1'b1;
            end

            // ====== MFSR ======
            OP_MFSR: begin
                alu_main   = OP_MFSR;
                reg_write  = 1'b1;
                reg_dst    = 1'b1;     // rd
                wb_sel     = WB_SPECIAL;
                mfsr_sel   = funct3;
            end

            // ====== MTSR ======
            OP_MTSR: begin
                alu_main = OP_MTSR;
                case (funct3)
                    3'b010: mtra = 1'b1;   // mtra
                    3'b011: mtat = 1'b1;   // mtat
                    3'b100: mthi = 1'b1;   // mthi
                    3'b101: mtlo = 1'b1;   // mtlo
                    default: ;
                endcase
            end

            // ====== HLT ======
            OP_HLT: begin
                hold_hlt = 1'b1;
            end

            default: begin
                // keep defaults
            end
        endcase
    end

endmodule
