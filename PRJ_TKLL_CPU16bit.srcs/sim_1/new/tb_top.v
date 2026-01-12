`timescale 1ns/1ps

module tb_top;

  reg clk;
  reg reset;
  reg interrupt_pending;
  reg [1:0] mux_clk;

  wire [15:0] r0, r1, r2, r3, r4, r5, r6, r7;

  // =========================
  // DUT (Device Under Test)
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
  // Clock Generation (10ns period = 100MHz)
  // =========================
  localparam CLK_PERIOD = 10;
  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  // =========================
  // Simulation Variables
  // =========================
  reg [1023:0] hexfile;
  integer cycles;
  integer instructions_executed;
  integer MAX_CYCLES = 2000;

  // =========================
  // TASK: In Báo cáo Hi?u n?ng
  // =========================
  task print_summary;
    input [1:0] exit_status; // 0: TIMEOUT, 1: PASS, 2: FAIL, 3: HLT
    real exec_time;
    real cpi;
    begin
        exec_time = cycles * CLK_PERIOD; // ns
        // V?i Single Cycle CPU, s? instr x?p x? s? cycle (tr? lúc reset/stall)
        // ? ?ây ta tính ??n gi?n CPI = 1
        
        $display("\n");
        $display("==========================================================");
        $display("              RISC-16 CPU PERFORMANCE REPORT              ");
        $display("==========================================================");
        
        case(exit_status)
            0: $display(" STATUS          : TIMEOUT (Max Cycles Reached)");
            1: $display(" STATUS          : TEST PASSED (Success Code Received)");
            2: $display(" STATUS          : TEST FAILED (Error Code Received)");
            3: $display(" STATUS          : HALTED (HLT Instruction Executed)");
        endcase
        
        $display("----------------------------------------------------------");
        $display(" Total Cycles    : %0d", cycles);
        $display(" Execution Time  : %0.2f ns", exec_time);
        $display(" Clock Frequency : 100 MHz");
        $display(" CPI (Approx)    : 1.00 (Single Cycle Architecture)");
        $display("==========================================================\n");
    end
  endtask

  // =========================
  // Initial Setup
  // =========================
  initial begin
    cycles = 0; 
    instructions_executed = 0;
    hexfile = "program.hex"; 
    
    if ($value$plusargs("HEX=%s", hexfile)) begin
        $display("[TB] Using HEX file: %s", hexfile);
    end

    interrupt_pending = 1'b0;
    mux_clk = 2'b00;
    reset = 1'b1;

    // Load ROM
    $readmemh(hexfile, dut.IM0.rom);

    repeat (5) @(posedge clk); 
    reset = 1'b0;
    
    $display("[TB] CPU Started...");
  end

  // =========================
  // Debug Signals
  // =========================
  wire [15:0] pc_now     = dut.pc; 
  wire [15:0] instr_now  = dut.IM0.rom[pc_now[15:1]]; 
  
  wire mem_write_en_spy  = dut.mem_write;
  wire [15:0] mem_addr_spy   = dut.ALU_out;   
  wire [15:0] mem_wdata_spy  = dut.readB_out; 

  localparam [15:0] TEST_PORT = 16'hFFFC;

  // =========================
  // Main Monitor Loop
  // =========================
  always @(posedge clk) begin
    if (!reset) begin
        cycles = cycles + 1;

        // Trace log (Có th? comment l?i n?u mu?n console g?n h?n)
        $display("T=%04d | PC=%h | Instr=%h | R1=%h R2=%h R3=%h | WB=%h",
                 cycles, pc_now, instr_now, r1, r2, r3, dut.wb_data);

        // 1. Ki?m tra PASS/FAIL
        if (mem_write_en_spy && mem_addr_spy == TEST_PORT) begin
          if (mem_wdata_spy == 16'h0001) begin
             print_summary(1); // PASS
          end else begin
             print_summary(2); // FAIL
          end
          $finish;
        end

        // 2. Ki?m tra l?nh HLT (Stop)
        if (dut.hold_hlt || instr_now[15:12] == 4'b1111) begin
             print_summary(3); // HALTED
             $finish;
        end

        // 3. Ki?m tra Timeout
        if (cycles > MAX_CYCLES) begin
          print_summary(0); // TIMEOUT
          $finish;
        end
    end
  end

endmodule