`timescale 1ns/1ps
module tb_jump;

  reg [15:0] pc;
  reg [15:0] instruction;
  wire [15:0] jump_target;

  Jump dut(.pc(pc), .instruction(instruction), .jump_target(jump_target));

  task CHECK;
    input cond;
    input [255:0] msg;
    begin
      if(!cond) begin $display("FAIL: %s", msg); $finish; end
    end
  endtask

  initial begin
    $display("=== tb_jump start ===");

    pc = 16'hA000;             // pc[15:13] = 101
    instruction = {4'b0111, 12'h123};  // addr=0x123
    #1;
    CHECK(jump_target[15:13]==pc[15:13], "Jump high bits wrong");
    CHECK(jump_target[0]==1'b0, "Jump alignment bit0 not 0");
    CHECK(jump_target[12:1]==12'h123, "Jump addr field wrong");

    $display("PASS: tb_jump");
    $finish;
  end
endmodule
