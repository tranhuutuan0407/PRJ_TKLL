`timescale 1ns/1ps
module TOP(
    input wire clk,
    input wire reset,
    input wire interrupt_pending, 
    output wire [15:0] r0, r1, r2, r3, r4, r5, r6, r7,
    input wire [1:0] mux_clk
);

    localparam [15:0] CONST2 = 16'd2;

    // ==========================================
    // Interconnect Wires
    // ==========================================
    wire [15:0] pc, next_pc, pc_plus2;
    wire        hold_hlt;
    wire [15:0] instruction;
    
    // Decoder Outputs
    wire [3:0]  opcode;
    wire [2:0]  funct3;
    wire [2:0]  rs, rt, rd;
    wire [5:0]  imm6;
    
    // Control Signals
    wire reg_write, alu_src, reg_dst;
    wire mem_read, mem_write;
    wire branch_en, jump_en, jr_en;
    wire [1:0] wb_sel;
    wire [2:0] immtype;
    wire [3:0] alu_main;
    wire branch_type;
    wire [2:0] mfsr_sel;
    wire mtra, mtat, mthi, mtlo;
    wire hi_lo_from_alu;
    
    // Data Wires
    wire [15:0] readA_out, readB_out;
    wire [15:0] wb_data;
    wire [15:0] imm_out;
    wire [15:0] alu_B;
    wire [5:0]  alu_sel;
    wire [15:0] ALU_out;
    wire [15:0] alu_hi_data, alu_lo_data;
    wire        cmp_flag; // T? ALU (unused in Branch logic per your old design, but kept connected)
    wire [15:0] mem_read_data;
    wire [15:0] mfsr_data;

    // ==========================================
    // 1. IF Stage (Fetch)
    // ==========================================
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

    Ins_Mem IM0(
        .address(pc),
        .instr_raw(instruction)
        // Các outputs khác c?a IM0 không dùng n?a vì ?ã có Instr_Decoder
    );

    // ==========================================
    // 2. ID Stage (Decode)
    // ==========================================
    // Module tách logic bit slicing & Reg selection
    Instruction_Decoder DEC0(
        .instruction(instruction),
        .reg_dst(reg_dst),
        .opcode(opcode),
        .funct3(funct3),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        .imm6(imm6),
        .addr12() // Jump address handled inside Branch_Jump_Logic
    );

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

    reg_file RF0(
        .clk(clk),
        .reg_wrt(reg_write),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        .data(wb_data),
        .readA_out(readA_out),
        .readB_out(readB_out),
        .r0(r0), .r1(r1), .r2(r2), .r3(r3),
        .r4(r4), .r5(r5), .r6(r6), .r7(r7)
    );

    special_register SR0(
        .clk(clk),
        .rst(reset),
        .ra_signal(mtra), .at_signal(mtat),
        .hi_signal(mthi), .lo_signal(mtlo),
        .hi_from_alu_signal(hi_lo_from_alu),
        .lo_from_alu_signal(hi_lo_from_alu),
        .ra_data(readB_out), .at_data(readB_out),
        .hi_data(readB_out), .lo_data(readB_out),
        .pc(pc_plus2),
        .hi_from_alu_data(alu_hi_data),
        .lo_from_alu_data(alu_lo_data),
        .mfsr_sel(mfsr_sel),
        .mfsr_data(mfsr_data)
    );

    Imm_gen IMM0(
        .instruction(instruction),
        .imm_type(immtype),
        .imm_out(imm_out)
    );

    // ==========================================
    // 3. EX Stage (Execute)
    // ==========================================
    // Module Mux d? li?u
    Datapath_Mux DPMUX(
        .alu_src(alu_src),
        .readB_out(readB_out),
        .imm_out(imm_out),
        .wb_sel(wb_sel),
        .alu_out(ALU_out),
        .mem_read_data(mem_read_data),
        .mfsr_data(mfsr_data),
        .alu_B(alu_B),
        .wb_data(wb_data)
    );

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
        .cmp(cmp_flag)
    );

    // ==========================================
    // 4. MEM Stage (Memory Access)
    // ==========================================
    data_mem DM0(
        .clk(clk),
        .reset(reset),
        .mem_read_en(mem_read),
        .mem_write_en(mem_write),
        .addr(ALU_out),
        .write_data(readB_out),
        .read_data(mem_read_data)
    );

    // ==========================================
    // 5. Next PC Logic (Branch & Jump)
    // ==========================================
    // Module x? lý logic Next PC ph?c t?p
    Branch_Jump_Logic NEXTPC(
        .pc_plus2(pc_plus2),
        .instruction(instruction),
        .imm_out(imm_out),
        .readA_out(readA_out),
        .readB_out(readB_out),
        .branch_en(branch_en),
        .jump_en(jump_en),
        .jr_en(jr_en),
        .branch_type(branch_type),
        .next_pc(next_pc)
    );

endmodule