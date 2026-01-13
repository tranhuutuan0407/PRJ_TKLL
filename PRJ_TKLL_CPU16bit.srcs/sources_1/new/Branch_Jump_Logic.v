`timescale 1ns / 1ps
module Branch_Jump_Logic(
    input  wire [15:0] pc_plus2,
    input  wire [15:0] instruction,   // ?? tính Jump Target
    input  wire [15:0] imm_out,       // Offset cho Branch
    input  wire [15:0] readA_out,     // D? li?u Rs (dùng cho so sánh và JR)
    input  wire [15:0] readB_out,     // D? li?u Rt (dùng cho so sánh)
    input  wire        branch_en,
    input  wire        jump_en,
    input  wire        jr_en,
    input  wire        branch_type,   // 0: BNEQ, 1: BGTZ
    output wire [15:0] next_pc
);

    // 1. Logic So sánh (Compare Logic)
    wire cmp_bneq = (readA_out != readB_out);
    wire cmp_bgtz = ($signed(readA_out) > 0);
    
    // Logic quy?t ??nh có r? nhánh không
    wire branch_taken = branch_en & (branch_type ? cmp_bgtz : cmp_bneq);

    // 2. Tính toán ??a ch? ?ích
    // Branch Target
    wire [15:0] pc_branch_target;
    assign pc_branch_target = pc_plus2 + imm_out;

    // Jump Target
    wire [11:0] addr12 = instruction[11:0];
    wire [15:0] jump_target = { pc_plus2[15:13], addr12, 1'b0 };

    // 3. Priority Mux cho Next PC
    // Priority: JR > JUMP > BRANCH > PC+2
    assign next_pc = jr_en        ? readA_out :
                     jump_en      ? jump_target :
                     branch_taken ? pc_branch_target :
                     pc_plus2;

endmodule