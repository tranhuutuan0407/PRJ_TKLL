`timescale 1ns / 1ps

module tb_Ins_Mem;

    // 1. Inputs
    reg [15:0] address;

    // 2. Outputs
    wire [15:0] instr_raw;
    wire [3:0] opcode;
    wire [2:0] funct3;
    wire [2:0] rs_rtype, rt_rtype, rd;
    wire [2:0] rs_i, rt_i;
    wire [5:0] imm6;
    wire [11:0] addr12;

    // 3. Instantiate DUT
    Ins_Mem uut (
        .address(address), 
        .instr_raw(instr_raw), 
        .opcode(opcode), 
        .funct3(funct3), 
        .rs_rtype(rs_rtype), .rt_rtype(rt_rtype), .rd(rd), 
        .rs_i(rs_i), .rt_i(rt_i), .imm6(imm6), 
        .addr12(addr12)
    );

    integer f;

    initial begin
        // --- B??C 1: T?O FILE HEX TR??C ---
        f = $fopen("program.hex", "w");
        // S?A L?I: 3045 -> Rt=1 (Kh?p v?i mong ??i test case)
        // 3045 = 0011 000 001 000101 (Op=3, Rs=0, Rt=1, Imm=5)
        $fdisplay(f, "3045"); 
        
        // 1298 = 0001 001 010 011 000 (ADD r3, r1, r2)
        $fdisplay(f, "1298");
        
        // 700F = JUMP 15
        $fdisplay(f, "700F");
        $fclose(f);

        // --- B??C 2: CH? MODULE LOAD FILE ---
        // L?u ý: Ins_Mem load file t?i th?i ?i?m 0. 
        // N?u simulation th?c t? không load ???c, em c?n t?o file program.hex th? công 
        // và l?u vào th? m?c project_name.sim/sim_1/behav/xsim/
        
        $display("=== tb_Ins_Mem Start ===");
        #10; // ??i ?n ??nh

        // --- TEST CASE 1: ADDI (Addr 0) ---
        address = 16'h0000;
        #10;
        $display("TC1 ADDI: Raw=%h | Op=%b | Rs=%d | Rt=%d | Imm=%d", 
                 instr_raw, opcode, rs_i, rt_i, imm6);
        
        if (instr_raw === 16'h3045 && opcode === 4'b0011 && rs_i === 0 && rt_i === 1 && imm6 === 5)
            $display("-> PASS");
        else
            $display("-> FAIL (Check program.hex loading)");

        // --- TEST CASE 2: ADD (Addr 2 - Word 1) ---
        address = 16'h0002; 
        #10;
        $display("TC2 ADD : Raw=%h | Op=%b | Rs=%d | Rt=%d | Rd=%d", 
                 instr_raw, opcode, rs_rtype, rt_rtype, rd);

        if (instr_raw === 16'h1298 && opcode === 4'b0001 && rs_rtype === 1 && rt_rtype === 2 && rd === 3)
            $display("-> PASS");
        else
            $display("-> FAIL");

        // --- TEST CASE 3: JUMP (Addr 4 - Word 2) ---
        address = 16'h0004;
        #10;
        $display("TC3 JUMP: Raw=%h | Op=%b | Addr=%h", 
                 instr_raw, opcode, addr12);

        if (instr_raw === 16'h700F && opcode === 4'b0111 && addr12 === 12'h00F)
            $display("-> PASS");
        else
            $display("-> FAIL");

        $display("=== tb_Ins_Mem End ===");
        $finish;
    end

endmodule