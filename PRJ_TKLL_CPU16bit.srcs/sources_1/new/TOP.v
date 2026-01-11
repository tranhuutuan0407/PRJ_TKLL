`timescale 1ns/1ps

module TOP(
    input  wire        clk,
    input  wire        reset,
    input  wire        interrupt_pending,
    output wire [15:0] r0, r1, r2, r3, r4, r5, r6, r7,
    input  wire [1:0]  mux_clk
);

    localparam [15:0] CONST2 = 16'd2;

    // ===================== PC =====================
    wire [15:0] pc, next_pc, pc_plus2;
    wire        hold_hlt;

    program_counter PC0(
        .clk(clk),
        .reset(reset),
        .pc_in(next_pc),
        .hold_hlt(hold_hlt),
        .pc_out(pc)
    );

    pc_add_2 ADD2(
        .pc(pc),
        .imm(CONST2),
        .pc_out(pc_plus2)
    );

    // ===================== Instruction Decode =====================
    wire [15:0] instruction;          // locally reconstructed
    wire [3:0]  opcode;
    wire [2:0]  rd_raw, funct3;

    wire [2:0] rs_i, rt_i;
    wire [2:0] rs_rtype, rt_rtype;
    wire [11:0] addr12;
    wire [5:0]  imm6;

    // NOTE:
    // Ins_Mem (the one you uploaded earlier) does NOT have output "instruction"
    // so we only connect the fields it actually provides.
    Ins_Mem IM0(
        .address(pc),

        .opcode(opcode),
        .rd_raw(rd_raw),
        .funct3(funct3),

        .rs_i(rs_i),
        .rt_i(rt_i),
        .rs_rtype(rs_rtype),
        .rt_rtype(rt_rtype),

        .addr12(addr12),
        .imm6(imm6)
    );

    // Reconstruct a 16-bit instruction bus for modules that still expect it
    // Based on opcode (format: R/I/J)
    //
    // R-type: op | rs | rt | rd | funct
    // I-type: op | rs | rt | imm6
    // J-type: op | addr12
    //
    // If your Ins_Mem was fixed to match the spec, rs_rtype/rt_rtype/rd_raw are correct.
    assign instruction =
        (opcode == 4'b0011) ? {opcode, addr12} : // OP_JUMP (adjust if your opcode differs)
        // For all non-JUMP: assume I-type vs R-type by opcode group
        // R-type group in your design: 0000(ALU0),0001(ALU1),0010(SHIFT/ALU2),1010(MFSR),1011(MTSR)
        ((opcode==4'b0000)||(opcode==4'b0001)||(opcode==4'b0010)||(opcode==4'b1010)||(opcode==4'b1011))
            ? {opcode, rs_rtype, rt_rtype, rd_raw, funct3}
            : {opcode, rs_i, rt_i, imm6};

    // ===================== Control signals =====================
    wire reg_write, alu_src, reg_dst;
    wire mem_read, mem_write;
    wire branch_en, jump_en;
    wire [1:0] wb_sel;
    wire [2:0] immtype;
    wire [3:0] alu_main;
    wire branch_type, jr_en;

    wire [2:0] mfsr_sel;
    wire mtra, mtat, mthi, mtlo;
    wire hi_lo_from_alu;

    C_U CU0(
        .opcode(opcode),
        .funct3(funct3),

        .reg_write(reg_write),
        .alu_src(alu_src),
        .reg_dst(reg_dst),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch_en(branch_en),
        .jump_en(jump_en),
        .hold_hlt(hold_hlt),

        .wb_sel(wb_sel),
        .immtype(immtype),
        .alu_main(alu_main),
        .branch_type(branch_type),
        .jr_en(jr_en),

        .mfsr_sel(mfsr_sel),
        .mtra(mtra), .mtat(mtat), .mthi(mthi), .mtlo(mtlo),
        .hi_lo_from_alu(hi_lo_from_alu)
    );

    // ===================== Register File =====================
    wire is_rtype;
    assign is_rtype = (opcode==4'b0000) || (opcode==4'b0001) ||
                      (opcode==4'b0010) || (opcode==4'b1010) ||
                      (opcode==4'b1011);

    wire [2:0] rs_final = (is_rtype) ? rs_rtype : rs_i;
    wire [2:0] rt_final = (is_rtype) ? rt_rtype : rt_i;

    wire [2:0] rd = (reg_dst) ? rd_raw : rt_i;

    wire [15:0] readA_out, readB_out;
    wire [15:0] wb_data;

    reg_file RF0(
        .clk(clk),
        .reg_wrt(reg_write),
        .rs(rs_final),
        .rt(rt_final),
        .rd(rd),
        .data(wb_data),
        .readA_out(readA_out),
        .readB_out(readB_out),
        .r0(r0), .r1(r1), .r2(r2), .r3(r3),
        .r4(r4), .r5(r5), .r6(r6), .r7(r7)
    );

    // ===================== Immediate Generator =====================
    wire [15:0] imm_out;

    Imm_gen IMM0(
        .instruction(instruction),
        .imm_type(immtype),
        .imm_out(imm_out)
    );

    wire [15:0] alu_B = (alu_src) ? imm_out : readB_out;

    // ===================== ALU =====================
    wire [5:0]  alu_sel;
    wire [15:0] ALU_out;
    wire [15:0] alu_hi_data, alu_lo_data;
    wire        cmp;

    ALU_control ALUCTRL(
        .funct3(funct3),
        .alu_op(alu_main),
        .ALU_control(alu_sel)
    );

    ALU ALU0(
        .A(readA_out),
        .B(alu_B),
        .alu_sel(alu_sel),
        .ALU_out(ALU_out),
        .hi_out(alu_hi_data),
        .lo_out(alu_lo_data),
        .cmp(cmp)
    );

    // ===================== Data Memory =====================
    wire [15:0] read_data;

    data_mem DM0(
        .clk(clk),
        .reset(reset),
        .mem_read_en(mem_read),
        .mem_write_en(mem_write),
        .addr(ALU_out),
        .write_data(readB_out),
        .read_data(read_data)
    );

    // ===================== Special Registers =====================
    wire [15:0] mfsr_data;

    special_register SR0(
        .clk(clk),
        .rst(reset),

        .ra_signal(mtra),
        .at_signal(mtat),
        .hi_signal(mthi),
        .lo_signal(mtlo),

        .hi_from_alu_signal(hi_lo_from_alu),
        .lo_from_alu_signal(hi_lo_from_alu),

        .ra_data(readB_out),
        .at_data(readB_out),
        .hi_data(readB_out),
        .lo_data(readB_out),

        .pc(pc_plus2),

        .hi_from_alu_data(alu_hi_data),
        .lo_from_alu_data(alu_lo_data),

        .mfsr_sel(mfsr_sel),
        .mfsr_data(mfsr_data)
    );

    // ===================== Writeback =====================
    assign wb_data = (wb_sel == 2'b00) ? ALU_out   :
                     (wb_sel == 2'b01) ? read_data :
                     (wb_sel == 2'b10) ? mfsr_data :
                     ALU_out;

    // ===================== Branch & Jump =====================
    wire        branch_taken = branch_en & cmp;
    wire [15:0] pc_branch_target;
    wire [15:0] jump_target;

    add_pc BRADD(
        .pc(pc_plus2),
        .imm(imm_out),
        .pc_out(pc_branch_target)
    );

    Jump J0(
        .pc(pc_plus2),
        .instruction(instruction),
        .jump_target(jump_target)
    );

    assign next_pc = (jr_en)        ? readA_out        :
                     (jump_en)      ? jump_target      :
                     (branch_taken) ? pc_branch_target :
                                      pc_plus2;

    // Note: interrupt_pending and mux_clk are currently unused in your RTL
    // (safe to ignore unless your assignment requires interrupts/clock mux)

endmodule
