`timescale 1ns/1ps
module tb_alu;

  reg [15:0] A,B;
  reg [5:0] alu_sel;
  wire [15:0] ALU_out, hi_out, lo_out;
  wire cmp;

  ALU dut(.A(A), .B(B), .alu_sel(alu_sel), .ALU_out(ALU_out), .hi_out(hi_out), .lo_out(lo_out), .cmp(cmp));

  task CHECK;
    input cond;
    input [255:0] msg;
    begin
      if(!cond) begin $display("FAIL: %s", msg); $finish; end
    end
  endtask

  initial begin
    $display("=== tb_alu start ===");

    // SEL_ADDR_LHSH = 40
    alu_sel = 6'd40;
    A = 16'h0003; // rs[15:1]=1
    B = 16'h0000; #1;
    // expected: ({0, A[15:1]} + B)<<1 = (1)<<1 = 2
    CHECK(ALU_out==16'h0002, "LH/SH address spec wrong (rs lsb ignored)");

    // SEL_CMP_GTZ = 42
    alu_sel = 6'd42;
    A = 16'hFFFF; B = 0; #1; // -1
    CHECK(cmp==0, "BGTZ signed compare wrong for -1");

    A = 16'h0001; #1;        // +1
    CHECK(cmp==1, "BGTZ signed compare wrong for +1");

    // SEL_MULTU = 12
    alu_sel = 6'd12;
    A = 16'd300; B = 16'd4; #1; // 1200 => hi=0 lo=1200
    CHECK(lo_out==16'd1200, "MULTU lo_out wrong");
    CHECK(hi_out==16'd0, "MULTU hi_out wrong");

    $display("PASS: tb_alu");
    $finish;
  end

endmodule
