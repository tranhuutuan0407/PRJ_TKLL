`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Register File - RISC16
// - 8 General Purpose Registers: r0..r7 (each 16-bit)
// - r0 is hardwired to 0 (like $ZERO)
// - 2 read ports (combinational)
// - 1 write port (synchronous on posedge clk)
//
// Inputs:
//   reg_wrt : write enable
//   rs, rt  : read addresses
//   rd      : write address
//   data    : write data
//
// Outputs:
//   readA_out, readB_out : read data
//   r0..r7 : debug outputs
//////////////////////////////////////////////////////////////////////////////////

module reg_file(
    input  wire        clk,
    input  wire        reg_wrt,
    input  wire [2:0]  rs,
    input  wire [2:0]  rt,
    input  wire [2:0]  rd,
    input  wire [15:0] data,

    output wire [15:0] readA_out,
    output wire [15:0] readB_out,

    output wire [15:0] r0,
    output wire [15:0] r1,
    output wire [15:0] r2,
    output wire [15:0] r3,
    output wire [15:0] r4,
    output wire [15:0] r5,
    output wire [15:0] r6,
    output wire [15:0] r7
);

    reg [15:0] regs [0:7];
    integer i;

    // -------------------------
    // Read ports (combinational)
    // -------------------------
    assign readA_out = (rs == 3'd0) ? 16'h0000 : regs[rs];
    assign readB_out = (rt == 3'd0) ? 16'h0000 : regs[rt];

    // Debug outputs
    assign r0 = 16'h0000;      // hardwired
    assign r1 = regs[1];
    assign r2 = regs[2];
    assign r3 = regs[3];
    assign r4 = regs[4];
    assign r5 = regs[5];
    assign r6 = regs[6];
    assign r7 = regs[7];

    // -------------------------
    // Write port (posedge clk)
    // -------------------------
    always @(posedge clk) begin
        // Enforce r0 always zero
        regs[0] <= 16'h0000;

        if (reg_wrt && (rd != 3'd0)) begin
            regs[rd] <= data;
        end
    end

    // Optional: init regs to 0 (simulation convenience)
    initial begin
        for (i = 0; i < 8; i = i + 1) regs[i] = 16'h0000;
    end

endmodule
