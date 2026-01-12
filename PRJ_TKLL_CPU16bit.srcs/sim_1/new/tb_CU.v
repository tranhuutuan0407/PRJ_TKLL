`timescale 1ns/1ps
module tb_CU;

  reg  [3:0] opcode;
  reg  [2:0] funct3;

  wire reg_write, alu_src, reg_dst, mem_read, mem_write, branch_en, jump_en, hold_hlt;
  wire [1:0] wb_sel;
  wire [2:0] immtype;
  wire [3:0] alu_main;
  wire branch_type, jr_en;
  wire [2:0] mfsr_sel;
  wire mtra, mtat, mthi, mtlo;
  wire hi_lo_from_alu;

  C_U dut(
    .opcode(opcode), .funct3(funct3),
    .reg_write(reg_write), .alu_src(alu_src), .reg_dst(reg_dst),
    .mem_read(mem_read), .mem_write(mem_write),
    .branch_en(branch_en), .jump_en(jump_en), .hold_hlt(hold_hlt),
    .wb_sel(wb_sel), .immtype(immtype), .alu_main(alu_main),
    .branch_type(branch_type), .jr_en(jr_en),
    .mfsr_sel(mfsr_sel), .mtra(mtra), .mtat(mtat), .mthi(mthi), .mtlo(mtlo),
    .hi_lo_from_alu(hi_lo_from_alu)
  );

  task CHECK;
    input cond;
    input [255:0] msg;
    begin
      if (!cond) begin
        $display("FAIL: %s", msg);
        $finish;
      end
    end
  endtask

  initial begin
    $display("=== tb_CU start ===");

    // ADDI
    opcode = 4'b0011; funct3 = 3'b000; #1;
    CHECK(reg_write==1 && alu_src==1 && wb_sel==2'b00, "ADDI control wrong");

    // LH
    opcode = 4'b1000; #1;
    CHECK(mem_read==1 && reg_write==1 && wb_sel==2'b01, "LH control wrong");

    // SH
    opcode = 4'b1001; #1;
    CHECK(mem_write==1 && reg_write==0, "SH control wrong");

    // BNEQ
    opcode = 4'b0101; #1;
    CHECK(branch_en==1 && immtype==3'b010, "BNEQ control wrong");

    // BGTZ
    opcode = 4'b0110; #1;
    CHECK(branch_en==1 && immtype==3'b010, "BGTZ control wrong");

    // J
    opcode = 4'b0111; #1;
    CHECK(jump_en==1, "JUMP control wrong");

    // JR (ALU1 funct3=111)
    opcode = 4'b0001; funct3 = 3'b111; #1;
    CHECK(jr_en==1 && reg_write==0, "JR control wrong");

    // mult/div (ALU0 funct3=010)
    opcode = 4'b0000; funct3 = 3'b010; #1;
    CHECK(hi_lo_from_alu==1 && reg_write==0, "MULTU control wrong");

    // HLT
    opcode = 4'b1111; #1;
    CHECK(hold_hlt==1, "HLT control wrong");

    $display("PASS: tb_CU");
    $finish;
  end

endmodule


