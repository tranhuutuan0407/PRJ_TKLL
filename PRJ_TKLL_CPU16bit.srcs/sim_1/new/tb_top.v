`timescale 1ns/1ps

module tb_top;

  reg clk;
  reg reset;
  reg interrupt_pending;
  reg [1:0] mux_clk;

  wire [15:0] r0, r1, r2, r3, r4, r5, r6, r7;

  // =========================
  // DUT
  // =========================
  TOP dut (
    .clk(clk),
    .reset(reset),
    .interrupt_pending(interrupt_pending),
    .r0(r0), .r1(r1), .r2(r2), .r3(r3),
    .r4(r4), .r5(r5), .r6(r6), .r7(r7),
    .mux_clk(mux_clk)
  );

  // =========================
  // Clock 10ns
  // =========================
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // =========================
  // Load HEX file
  // =========================
  reg [1023:0] hexfile;

  initial begin
    hexfile = "program.hex";
    $value$plusargs("HEX=%s", hexfile);
    $display("[TB] Load HEX file: %s", hexfile);

    interrupt_pending = 1'b0;
    mux_clk = 2'b00;

    reset = 1'b1;
    repeat (2) @(posedge clk);
    reset = 1'b0;

    // Load vào ROM c?a Ins_Mem (instance tên IM0)
    $readmemh(hexfile, dut.IM0.rom);

    $display("[TB] B?t ??u ch?y CPU");
  end

  // =========================
  // Truy v?t PC + instruction
  // =========================
  wire [15:0] pc_now;
  assign pc_now = dut.pc;

  wire [14:0] waddr_now = pc_now[15:1];
  wire [15:0] instr_now = dut.IM0.rom[waddr_now];

  // =========================
  // C?ng báo k?t qu? test
  // =========================
  localparam [15:0] TEST_PORT = 16'hFFFC;

  wire mem_write_en = dut.mem_write;
  wire [15:0] mem_addr  = dut.ALU_out;
  wire [15:0] mem_wdata = dut.readB_out;

  // =========================
  // ?i?u khi?n ch?y
  // =========================
  integer cycles;
  integer MAX_CYCLES = 2000;

  always @(posedge clk) begin
    cycles = cycles + 1;

    // In trace
    $display("t=%0t PC=%h instr=%h | r0=%h r1=%h r2=%h r3=%h r4=%h r5=%h r6=%h r7=%h",
             $time, pc_now, instr_now,
             r0,r1,r2,r3,r4,r5,r6,r7);

    // ===== PASS / FAIL t? ch??ng trình =====
    if (mem_write_en && mem_addr == TEST_PORT) begin
      if (mem_wdata == 16'h0001) begin
        $display(">>> PASS: ch??ng trình báo thành công");
      end else begin
        $display(">>> FAIL: ch??ng trình báo l?i, mã = %h", mem_wdata);
      end
      $finish;
    end

    // ===== D?ng khi HLT =====
    if (dut.hold_hlt) begin
      $display(">>> HLT t?i PC=%h sau %0d chu k?", pc_now, cycles);
      $finish;
    end

    // Fallback: opcode HLT = F000
    if (instr_now == 16'hF000) begin
      $display(">>> HLT (opcode) t?i PC=%h", pc_now);
      $finish;
    end

    // ===== Timeout =====
    if (cycles > MAX_CYCLES) begin
      $display(">>> TIMEOUT: ch??ng trình không k?t thúc");
      $finish;
    end
  end

endmodule
