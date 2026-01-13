`timescale 1ns / 1ps
module Datapath_Mux(
    // ALU Input Mux inputs
    input  wire        alu_src,
    input  wire [15:0] readB_out,
    input  wire [15:0] imm_out,
    
    // Writeback Mux inputs
    input  wire [1:0]  wb_sel, // 00:ALU, 01:MEM, 10:SPEC
    input  wire [15:0] alu_out,
    input  wire [15:0] mem_read_data,
    input  wire [15:0] mfsr_data,

    // Outputs
    output wire [15:0] alu_B,
    output wire [15:0] wb_data
);

    // ALU Input B Selection
    assign alu_B = alu_src ? imm_out : readB_out;

    // Writeback Data Selection
    assign wb_data = (wb_sel == 2'b00) ? alu_out :
                     (wb_sel == 2'b01) ? mem_read_data :
                     (wb_sel == 2'b10) ? mfsr_data :
                     alu_out; // Default
endmodule