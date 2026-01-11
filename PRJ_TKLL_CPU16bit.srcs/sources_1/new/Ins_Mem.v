`timescale 1ns / 1ps

module Ins_Mem (
    input  wire [15:0] address,      // PC (byte address)

    // Full raw instruction word (for Imm_gen / Jump / debug)
    output wire [15:0] instr_raw,

    // Common fields
    output wire [3:0]  opcode,
    output wire [2:0]  funct3,

    // R-type fields: op | rs | rt | rd | funct
    output wire [2:0]  rs_rtype,
    output wire [2:0]  rt_rtype,
    output wire [2:0]  rd,

    // I-type fields: op | rs | rt | imm6
    output wire [2:0]  rs_i,
    output wire [2:0]  rt_i,
    output wire [5:0]  imm6,

    // J-type field: op | addr12
    output wire [11:0] addr12
);

    // 32K instructions x 16-bit
    // Address space 2^16 bytes => 2^15 halfwords (instructions)
    reg [15:0] rom [0:32767];

    // word index (each instruction is 2 bytes)
    wire [14:0] waddr = address[15:1];

    wire [15:0] instruction = rom[waddr];

    // Export raw instruction
    assign instr_raw = instruction;

    // Common
    assign opcode = instruction[15:12];
    assign funct3 = instruction[2:0];

    // -----------------------------
    // R-type: op | rs | rt | rd | funct
    //        15:12 11:9  8:6  5:3  2:0
    // -----------------------------
    assign rs_rtype = instruction[11:9];
    assign rt_rtype = instruction[8:6];
    assign rd       = instruction[5:3];

    // -----------------------------
    // I-type: op | rs | rt | imm6
    //        15:12 11:9  8:6  5:0
    // -----------------------------
    assign rs_i = instruction[11:9];
    assign rt_i = instruction[8:6];
    assign imm6 = instruction[5:0];

    // -----------------------------
    // J-type: op | addr12
    //        15:12 11:0
    // -----------------------------
    assign addr12 = instruction[11:0];

    integer i;

    initial begin
        // Optional: clear ROM to avoid X if readmemh fails
        for (i = 0; i < 32768; i = i + 1) begin
            rom[i] = 16'h0000;
        end

        // Load program
        // Vivado/XSim will look relative to simulation run dir, and your tb script exports program.hex there.
        $display("[Ins_Mem] readmemh start");
        $readmemh("program.hex", rom);
//           $readmemh("program_addi.hex", rom);

        // Quick debug dump
        $display("[Ins_Mem] ROM[0]=%h ROM[1]=%h ROM[6]=%h ROM[7]=%h",
                 rom[0], rom[1], rom[6], rom[7]);
    end

endmodule



