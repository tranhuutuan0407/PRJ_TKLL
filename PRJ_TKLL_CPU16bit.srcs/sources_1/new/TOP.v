`timescale 1ns/1ps

module TOP(
    input  wire        clk,
    input  wire        reset,
    input  wire        interrupt_pending,
    output wire [15:0] r0, r1, r2, r3, r4, r5, r6, r7,
    input  wire [1:0]  mux_clk
);

    localparam [15:0] CONST2 = 16'd2;

    // =========================================================
    // PC
    // =========================================================
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

    // =========================================================
    // Instruction Memory (RAW + FIELDS)
    // =========================================================
    wire [15:0] instruction;   // raw 16-bit from ROM
    wire [3:0]  opcode;
    wire [2:0]  funct3;

    wire [2:0]  rs_rtype, rt_rtype, rd_raw;
    wire [2:0]  rs_i, rt_i;
    wire [11:0] addr12;
    wire [5:0]  imm6;

    Ins_Mem IM0(
        .address(pc),
        .instr_raw(instruction),

        .opcode(opcode),
        .funct3(funct3),

        .rs_rtype(rs_rtype),
        .rt_rtype(rt_rtype),
        .rd(rd_raw),

        .rs_i(rs_i),
        .rt_i(rt_i),

        .imm6(imm6),
        .addr12(addr12)
    );

    // =========================================================
    // Control Unit
    // =========================================================
    wire        reg_write, alu_src, reg_dst;
    wire        mem_read, mem_write;
    wire        branch_en, jump_en;
    wire [1:0]  wb_sel;
    wire [2:0]  immtype;
    wire [3:0]  alu_main;
    wire        branch_type, jr_en;

    wire [2:0]  mfsr_sel;
    wire        mtra, mtat, mthi, mtlo;
    wire        hi_lo_from_alu;

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
        .mtra(mtra),
        .mtat(mtat),
        .mthi(mthi),
        .mtlo(mtlo),
        .hi_lo_from_alu(hi_lo_from_alu)
    );

    // =========================================================
    // Register File select (minimal muxing in TOP)
    // =========================================================
    localparam [3:0] OP_ALU0 = 4'b0000;
    localparam [3:0] OP_ALU1 = 4'b0001;
    localparam [3:0] OP_ALU2 = 4'b0010;
    localparam [3:0] OP_MFSR = 4'b1010;
    localparam [3:0] OP_MTSR = 4'b1011;

    wire is_rtype;
    assign is_rtype = (opcode == OP_ALU0) || (opcode == OP_ALU1) ||
                      (opcode == OP_ALU2) || (opcode == OP_MFSR) ||
                      (opcode == OP_MTSR);

    wire [2:0] rs_final = is_rtype ? rs_rtype : rs_i;
    wire [2:0] rt_final = is_rtype ? rt_rtype : rt_i;

    wire [2:0] rd = reg_dst ? rd_raw : rt_i;

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
        .r0(r0),
        .r1(r1),
        .r2(r2),
        .r3(r3),
        .r4(r4),
        .r5(r5),
        .r6(r6),
        .r7(r7)
    );

    // =========================================================
    // Immediate Generator (uses RAW instruction)
    // =========================================================
    wire [15:0] imm_out;

    Imm_gen IMM0(
        .instruction(instruction),
        .imm_type(immtype),
        .imm_out(imm_out)
    );

    wire [15:0] alu_B = alu_src ? imm_out : readB_out;

    // =========================================================
    // ALU + ALU Control
    // =========================================================
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

    // =========================================================
    // Data Memory
    // =========================================================
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

    // =========================================================
    // Special Registers
    // =========================================================
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

    // =========================================================
    // Writeback
    // wb_sel: 00 ALU, 01 MEM, 10 SPECIAL
    // =========================================================
    assign wb_data = (wb_sel == 2'b00) ? ALU_out   :
                     (wb_sel == 2'b01) ? read_data :
                     (wb_sel == 2'b10) ? mfsr_data  :
                     ALU_out;

    // =========================================================
    // Branch & Jump (uses RAW instruction)
    // =========================================================
 wire cmp_bneq = (readA_out != readB_out);
wire cmp_bgtz = ($signed(readA_out) > 0);
wire branch_taken = branch_en & (branch_type ? cmp_bgtz : cmp_bneq);


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

    // Priority: JR > JUMP > BRANCH > PC+2
    assign next_pc = jr_en        ? readA_out        :
                     jump_en      ? jump_target      :
                     branch_taken ? pc_branch_target :
                                  pc_plus2;

    // interrupt_pending and mux_clk currently unused

endmodule
