`timescale 1ns/1ps
module tb_aluctrl;

  reg [2:0] funct3;
  reg [3:0] alu_op;
  wire [5:0] alu_sel;

  ALU_control dut(.funct3(funct3), .alu_op(alu_op), .ALU_control(alu_sel));

  task CHECK;
    input cond;
    input [255:0] msg;
    begin
      if(!cond) begin $display("FAIL: %s", msg); $finish; end
    end
  endtask

  initial begin
    $display("=== tb_aluctrl start ===");

    // ALU0 multu => SEL_MULTU = 12
    alu_op=4'b0000; funct3=3'b010; #1;
    CHECK(alu_sel==6'd12, "ALU0 multu mapping wrong");

    // BNEQ => SEL_CMP_NEQ = 41
    alu_op=4'b0101; funct3=3'b000; #1;
    CHECK(alu_sel==6'd41, "BNEQ mapping wrong");

    // BGTZ => SEL_CMP_GTZ = 42
    alu_op=4'b0110; #1;
    CHECK(alu_sel==6'd42, "BGTZ mapping wrong");

    // LH => SEL_ADDR_LHSH = 40
    alu_op=4'b1000; #1;
    CHECK(alu_sel==6'd40, "LH addr mapping wrong");

    $display("PASS: tb_aluctrl");
    $finish;
  end

endmodule
