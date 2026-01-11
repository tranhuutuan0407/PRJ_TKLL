`timescale 1ns/1ps

module tb_top;

  // ===== DUT inputs =====
  reg clk;
  reg reset;
  reg interrupt_pending;
  reg [1:0] mux_clk;

  // ===== DUT outputs =====
  wire [15:0] r0,r1,r2,r3,r4,r5,r6,r7;

  // ===== Instantiate DUT =====
  TOP dut (
    .clk(clk),
    .reset(reset),
    .interrupt_pending(interrupt_pending),
    .r0(r0),.r1(r1),.r2(r2),.r3(r3),.r4(r4),.r5(r5),.r6(r6),.r7(r7),
    .mux_clk(mux_clk)
  );

  // ===== Clock =====
  initial begin
    clk = 0;
    forever #5 clk = ~clk;   // 10ns period
  end

  // ===== Encode helpers =====
  // R-type: opcode rd rs rt funct3
  function [15:0] ENCODE_R;
    input [3:0] op;
    input [2:0] rd;
    input [2:0] rs;
    input [2:0] rt;
    input [2:0] f3;
    begin
      ENCODE_R = {op, rd, rs, rt, f3};
    end
  endfunction

  // I-type: opcode rs rt imm6
  function [15:0] ENCODE_I;
    input [3:0] op;
    input [2:0] rs;
    input [2:0] rt;
    input [5:0] imm6;
    begin
      ENCODE_I = {op, rs, rt, imm6};
    end
  endfunction

  // ===== Write ROM task =====
  task ROM_WRITE;
    input integer word_index;
    input [15:0] instr;
    begin
      dut.IM0.rom[word_index] = instr;
    end
  endtask

  // ===== Opcodes (match your CU) =====
  localparam OP_ADDI = 4'b0011;
  localparam OP_ALU1 = 4'b0001;
  localparam OP_HLT  = 4'b1111;

  // JR funct3 = 111 (in ALU1)
  localparam F3_JR   = 3'b111;

  // ===== Simple assertion task =====
  task CHECK;
    input cond;
    input [255:0] msg;
    begin
      if(!cond) begin
        $display("FAIL: %s", msg);
        $finish;
      end
    end
  endtask

  // ===== Debug monitor =====
  initial begin
    $display(" time   PC    instr   | r4 r5  | regW rd wb_data jr_en readA_out hold_hlt");
    $monitor("%4t  %h  %h  | %0d %0d |  %b   %0d  %h   %b    %h     %b",
      $time,
      dut.pc,
      dut.instruction,
      r4, r5,
      dut.reg_write,
      dut.rd,
      dut.wb_data,
      dut.jr_en,
      dut.readA_out,
      dut.hold_hlt
    );
  end

  integer i;
  reg [15:0] pc_hold;

  initial begin
    // ===== init =====
    reset = 1;
    interrupt_pending = 0;
    mux_clk = 2'b00;

    // clear ROM
    for (i=0; i<64; i=i+1)
      ROM_WRITE(i, 16'h0000);

    // ======================================================
    // PROGRAM (byte PC increments by 2, word index = PC>>1)
    //
    // word0 @PC=0x0000 : addi r5, r0, 12      -> r5 = 12 (0x000C)
    // word1 @PC=0x0002 : jr r5                -> PC = 0x000C (word6)
    // word2 @PC=0x0004 : hlt                  -> should NOT reach if JR works
    //
    // word6 @PC=0x000C : addi r4, r0, 9       -> r4 = 9
    // word7 @PC=0x000E : hlt                  -> PC must hold here
    // ======================================================

    // word0: addi r5, r0, 12
    ROM_WRITE(0, ENCODE_I(OP_ADDI, 3'd0, 3'd5, 6'd12));

    // word1: jr r5
    // R-type: opcode=ALU1, rd=0, rs=5, rt=0, funct3=JR
    ROM_WRITE(1, ENCODE_R(OP_ALU1, 3'd0, 3'd5, 3'd0, F3_JR));

    // word2: hlt (should not reach)
    ROM_WRITE(2, {OP_HLT, 12'h000});

    // word6: addi r4, r0, 9
    ROM_WRITE(6, ENCODE_I(OP_ADDI, 3'd0, 3'd4, 6'd9));

    // word7: hlt (must stop here)
    ROM_WRITE(7, {OP_HLT, 12'h000});

    // ===== release reset =====
    #20;
    reset = 0;

    // run enough cycles
    #200;

    $display("\n==== FINAL CHECK ====");
    $display("r5=%0d (expect 12)", r5);
    $display("r4=%0d (expect 9)",  r4);

    CHECK(r5 === 16'd12, "r5 not written correctly by ADDI");
    CHECK(r4 === 16'd9,  "r4 not written correctly after JR jump");

    // Check HLT holds PC at word7 (PC=0x000E)
    pc_hold = dut.pc;
    #50;
    CHECK(dut.pc === pc_hold, "PC not held on HLT");

    $display("PASS: TOP works for ADDI + JR + HLT");
    $finish;
  end

endmodule
