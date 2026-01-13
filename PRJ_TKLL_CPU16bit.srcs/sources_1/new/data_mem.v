`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Data Memory - RISC16
//
// - 16-bit word-addressable memory implemented as reg [15:0] mem[]
// - Input addr is byte address, assumed aligned (bit0 = 0) for LH/SH
// - Index = addr[15:1]  (addr >> 1)
//
// Ports:
//   mem_read_en  : enable read
//   mem_write_en : enable write
//   addr         : byte address (from ALU_out)
//   write_data   : 16-bit store data (rt)
//   read_data    : 16-bit load data
//
// Notes:
// - For synthesis on FPGA, you can replace with BRAM.
// - Here is a simple behavioral memory suitable for simulation and basic synth.
//////////////////////////////////////////////////////////////////////////////////

module data_mem(
    input  wire        clk,
    input  wire        reset,
    input  wire        mem_read_en,
    input  wire        mem_write_en,
    input  wire [15:0] addr,
    input  wire [15:0] write_data,
    output reg  [15:0] read_data
);

    // memory size: 2^15 words = 32768 words (because address space 2^16 bytes)
    // For synthesis/resource reasons in FPGA, you may reduce size.
    reg [15:0] mem [0:32767];
    integer i;

    // word index = addr >> 1
    wire [14:0] waddr = addr[15:1];
    initial begin
//        $readmemh("program.hex", mem); // Ho?c dùng vòng l?p for ? ?ây n?u mu?n xóa tr?ng
         for (i = 0; i < 32768; i = i + 1) mem[i] = 16'h0000;
    end
    // Read is combinational when enabled
    always @(*) begin
        if (mem_read_en)
            read_data = mem[waddr];
        else
            read_data = 16'h0000;
    end

    // Write on posedge clk when enabled
    always @(posedge clk) begin
        if (mem_write_en) begin
            mem[waddr] <= write_data;
        end
    end

endmodule
