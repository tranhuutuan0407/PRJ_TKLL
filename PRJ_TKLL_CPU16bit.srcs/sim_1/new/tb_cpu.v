`timescale 1ns/1ps

module tb_cpu;

  reg clk;
  reg reset;
  reg interrupt_pending;
  reg [1:0] mux_clk;

  wire [15:0] r0, r1, r2, r3, r4, r5, r6, r7;

  // DUT
  TOP dut (
    .clk(clk),
    .reset(reset),
    .interrupt_pending(interrupt_pending),
    .r0(r0), .r1(r1), .r2(r2), .r3(r3),
    .r4(r4), .r5(r5), .r6(r6), .r7(r7),
    .mux_clk(mux_clk)
  );

  // Clock 10ns period
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  task expect_reg;
    input [2:0] idx;
    input [15:0] exp;
    reg [15:0] got;
    begin
      case (idx)
        3'd0: got = r0;
        3'd1: got = r1;
        3'd2: got = r2;
        3'd3: got = r3;
        3'd4: got = r4;
        3'd5: got = r5;
        3'd6: got = r6;
        3'd7: got = r7;
        default: got = 16'hxxxx;
      endcase

      if (got !== exp) begin
        $display("FAIL: r%0d = %h (expect %h)", idx, got, exp);
        $finish;
      end else begin
        $display("PASS: r%0d = %h", idx, got);
      end
    end
  endtask

  integer cycles;

  initial begin
    interrupt_pending = 1'b0;
    mux_clk = 2'b00;

    reset = 1'b1;
    repeat (2) @(posedge clk);
    reset = 1'b0;

    cycles = 0;

    // Run until HLT or timeout
    while (cycles < 200) begin
      @(posedge clk);
      cycles = cycles + 1;

      // Neu ban muon theo doi PC/instr, bat cac signal noi bo (neu dut co)
      // $display("t=%0t PC=%h r4=%h r5=%h", $time, dut.pc, r4, r5);

      if (dut.hold_hlt === 1'b1) begin
        $display("HLT detected at cycle %0d, time %0t", cycles, $time);
        disable run_done;
      end
    end

    $display("FAIL: Timeout, no HLT");
    $finish;

    run_done: begin end

    // Moi test se sua phan EXPECT o day (hoac tao file tb rieng)
    // Vi du:
     expect_reg(3'd5, 16'd12);

    $display("DONE");
    $finish;
  end

endmodule
