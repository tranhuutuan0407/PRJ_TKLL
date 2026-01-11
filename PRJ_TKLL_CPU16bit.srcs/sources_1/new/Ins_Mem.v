`timescale 1ns / 1ps

module Ins_Mem (
    input  wire [15:0] address,      // PC (byte address)
    output wire [3:0]  opcode,
    output wire [2:0]  funct3,

    // R-type fields (valid when opcode is R-type group)
    output wire [2:0]  rs_rtype,
    output wire [2:0]  rt_rtype,
    output wire [2:0]  rd,             // rd_raw in TOP (keep name if you want)

    // I-type fields
    output wire [2:0]  rs_i,
    output wire [2:0]  rt_i,

    // J-type field
    output wire [11:0] addr12,

    // imm6 (I-type)
    output wire [5:0]  imm6
);

    // 32K instructions x 16-bit (since address space 2^16 bytes => 2^15 halfwords)
    reg [15:0] rom [0:32767];

    // word index (each instruction is 2 bytes)
    wire [14:0] waddr = address[15:1];

    wire [15:0] instruction = rom[waddr];

    // Common
    assign opcode = instruction[15:12];
    assign funct3 = instruction[2:0];

    // -----------------------------
    // FIXED: R-type field positions
    // R-type: op | rs | rt | rd | funct
    //        15:12 11:9  8:6  5:3  2:0
    // -----------------------------
    assign rs_rtype = instruction[11:9];
    assign rt_rtype = instruction[8:6];
    assign rd       = instruction[5:3];

    // I-type: op | rs | rt | imm6
    //        15:12 11:9  8:6  5:0
    assign rs_i  = instruction[11:9];
    assign rt_i  = instruction[8:6];
    assign imm6  = instruction[5:0];

    // J-type: op | addr12
    assign addr12 = instruction[11:0];

    integer i;
    initial begin
        // Default clear
        for (i = 0; i < 32768; i = i + 1) begin
            rom[i] = 16'h0000;
        end

        // IMPORTANT: Uncomment and point to your program file
        // $readmemh("program.hex", rom);
    end

endmodule



