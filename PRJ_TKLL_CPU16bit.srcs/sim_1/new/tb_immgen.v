`timescale 1ns/1ps
module tb_immgen;

  reg [15:0] instruction;
  reg [2:0] imm_type;
  wire [15:0] imm_out;

  Imm_gen dut(.instruction(instruction), .imm_type(imm_type), .imm_out(imm_out));

  task CHECK;
    input cond;
    input [255:0] msg;
    begin
      if(!cond) begin $display("FAIL: %s", msg); $finish; end
    end
  endtask

  initial begin
    $display("=== tb_immgen start ===");

    // imm6 = 1
    instruction = 16'h0001; // imm6=000001
    imm_type = 3'b001; #1;
    CHECK(imm_out==16'd1, "IMM_SEXT6 wrong for +1");

    imm_type = 3'b010; #1;
    CHECK(imm_out==16'd2, "IMM_BR wrong for +1");

    // imm6 = -1 (0x3F)
    instruction[5:0] = 6'h3F;
    imm_type = 3'b001; #1;
    CHECK(imm_out==16'hFFFF, "IMM_SEXT6 wrong for -1");

    imm_type = 3'b010; #1;
    CHECK(imm_out==16'hFFFE, "IMM_BR wrong for -1");

    $display("PASS: tb_immgen");
    $finish;
  end

endmodule


