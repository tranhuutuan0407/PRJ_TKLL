`timescale 1ns/1ps

module tb_top;

  // ---------------- DUT I/O ----------------
  reg         clk;
  reg         reset;
  reg         interrupt_pending;
  reg  [1:0]  mux_clk;

  wire [15:0] r0, r1, r2, r3, r4, r5, r6, r7;

  TOP dut (
    .clk(clk),
    .reset(reset),
    .interrupt_pending(interrupt_pending),
    .r0(r0), .r1(r1), .r2(r2), .r3(r3),
    .r4(r4), .r5(r5), .r6(r6), .r7(r7),
    .mux_clk(mux_clk)
  );

  // ---------------- Clock ----------------
  // 100MHz equivalent: period 10ns
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // ---------------- Main ----------------
  integer cycle;
  localparam integer MAX_CYCLES = 2000;

  initial begin
    // defaults
    interrupt_pending = 1'b0;
    mux_clk = 2'b00;

    // reset pulse
    reset = 1'b1;
    repeat (5) @(posedge clk);
    reset = 1'b0;

    // Load program into instruction ROM
    // Path is relative to simulation working dir.
    // Put program.hex under: <your_project>.sim/sim_1/behav/xsim/
    // OR use absolute path.
    $display("[TB] Loading program.hex into Ins_Mem ROM...");
    $readmemh("program.hex", dut.IM0.rom);

    // Optional: clear data memory too (if you want deterministic)
    // Uncomment if your data_mem module has mem array named "mem"
    // $display("[TB] Clearing data memory...");
    // for (i = 0; i < 32768; i = i + 1) dut.DM0.mem[i] = 16'h0000;

    $display("[TB] Start simulation.");

    // Run until HLT (hold_hlt asserted) or timeout
    for (cycle = 0; cycle < MAX_CYCLES; cycle = cycle + 1) begin
      @(posedge clk);

      // Print a light trace each cycle (comment out if too noisy)
      $display("C%0d PC=%h HLT=%b | r1=%h r2=%h r3=%h r4=%h r5=%h r6=%h r7=%h",
               cycle, dut.pc, dut.hold_hlt, r1, r2, r3, r4, r5, r6, r7);

      if (dut.hold_hlt) begin
        $display("[TB] HLT detected at cycle %0d, PC=%h", cycle, dut.pc);
        $finish;
      end
    end

    $display("[TB] TIMEOUT: exceeded MAX_CYCLES=%0d without HLT", MAX_CYCLES);
    $finish;
  end

  // ---------------- Wave dump ----------------
  // XSim supports $dumpfile/$dumpvars in some flows;
  // Vivado usually uses .wdb automatically, but this doesn't hurt.
  initial begin
    $dumpfile("tb_top.vcd");
    $dumpvars(0, tb_top);
  end

endmodule
