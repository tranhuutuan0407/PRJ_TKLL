`timescale 1ns / 1ps

module Ins_Mem (
    input  wire [15:0] address,      // PC (byte address)
    output wire [15:0] instr_raw     // Full raw instruction word to TOP
);

    // 32K instructions x 16-bit
    // Address space 2^16 bytes => 2^15 halfwords (instructions)
    reg [15:0] rom [0:32767];

    // word index (each instruction is 2 bytes)
    // Shift right 1 bit to convert Byte Address -> Word Address
    wire [14:0] waddr = address[15:1];

    // Read memory
    assign instr_raw = rom[waddr];

    integer i;

    initial begin
        // 1. Clear ROM to avoid 'X' (undefined states)
        for (i = 0; i < 32768; i = i + 1) begin
            rom[i] = 16'h0000;
        end

        // 2. Load program from HEX file
        // Note: program.hex must contain 16-bit hex values (e.g., "3001")
        $display("[Ins_Mem] Loading program.hex...");
        $readmemh("program.hex", rom);

        // 3. Quick debug dump
        $display("[Ins_Mem] Loaded: ROM[0]=%h, ROM[1]=%h", rom[0], rom[1]);
    end

endmodule