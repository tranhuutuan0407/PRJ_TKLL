`timescale 1ns / 1ps

module Ins_Mem (
    input  wire [15:0] address,      // PC (byte address)

    // decoded fields
    output wire [3:0]  opcode,
    output wire [2:0]  rd_raw,
    output wire [2:0]  funct3,

    output wire [2:0]  rs_i,
    output wire [2:0]  rt_i,

    output wire [2:0]  rs_rtype,
    output wire [2:0]  rt_rtype,

    output wire [11:0] addr12,
    output wire [5:0]  imm6,

    // full instruction for Imm_gen / Jump
    output wire [15:0] instruction
);

    // 32K halfwords = 64KB / 2 bytes per instruction
    reg [15:0] rom [0:32767];

    // PC is byte address; instruction index = PC/2
    wire [14:0] waddr = address[15:1];

    // combinational read
    assign instruction = rom[waddr];

    // Common
    assign opcode = instruction[15:12];
    assign funct3 = instruction[2:0];

    // =========================
    // Correct bit fields per spec
    // R-type: op[15:12] | rs[11:9] | rt[8:6] | rd[5:3] | funct[2:0]
    // I-type: op[15:12] | rs[11:9] | rt[8:6] | imm6[5:0]
    // J-type: op[15:12] | addr12[11:0]
    // =========================
    assign rs_rtype = instruction[11:9];
    assign rt_rtype = instruction[8:6];
    assign rd_raw   = instruction[5:3];

    assign rs_i     = instruction[11:9];
    assign rt_i     = instruction[8:6];
    assign imm6     = instruction[5:0];

    assign addr12   = instruction[11:0];

    integer i;
    initial begin
        for (i = 0; i < 32768; i = i + 1)
            rom[i] = 16'h0000;

        // $readmemh("program.hex", rom);
    end

endmodule



