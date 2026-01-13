`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Special Register File - RISC16
//
// Special registers:
//  - ZERO : constant 0
//  - PC   : provided as input (use pc_plus2 recommended)
//  - RA   : return address
//  - AT   : assembler temporary
//  - HI/LO: mult/div results
//
// Inputs:
//  - mtra/mtat/mthi/mtlo : write enables for RA/AT/HI/LO from rt (readB_out)
//  - hi_from_alu_signal / lo_from_alu_signal : write enables for HI/LO from ALU (mult/div)
//  - pc : current PC (or pc_plus2) used for mfpc
//  - mfsr_sel : selects which special reg to read out for MFSR
//
// Output:
//  - mfsr_data : data selected by mfsr_sel
//////////////////////////////////////////////////////////////////////////////////

module special_register(
    input  wire        clk,
    input  wire        rst,

    // write enables from CU
    input  wire        ra_signal,     // mtra
    input  wire        at_signal,     // mtat
    input  wire        hi_signal,     // mthi
    input  wire        lo_signal,     // mtlo

    input  wire        hi_from_alu_signal,  // mult/div -> HI
    input  wire        lo_from_alu_signal,  // mult/div -> LO

    // write data sources (usually rt value)
    input  wire [15:0] ra_data,
    input  wire [15:0] at_data,
    input  wire [15:0] hi_data,
    input  wire [15:0] lo_data,

    // PC input (recommended: pc_plus2)
    input  wire [15:0] pc,

    // ALU HI/LO results
    input  wire [15:0] hi_from_alu_data,
    input  wire [15:0] lo_from_alu_data,

    // select for MFSR
    input  wire [2:0]  mfsr_sel,

    // output for MFSR
    output reg  [15:0] mfsr_data
);

    // internal special registers
    reg [15:0] RA;
    reg [15:0] AT;
    reg [15:0] HI;
    reg [15:0] LO;

    // Reset + write logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            RA <= 16'h0000;
            AT <= 16'h0000;
            HI <= 16'h0000;
            LO <= 16'h0000;
        end
        else begin
            // MTSR writes from rt
            if (ra_signal) RA <= ra_data;
            if (at_signal) AT <= at_data;
            if (hi_signal) HI <= hi_data;
            else if (hi_from_alu_signal) HI <= hi_from_alu_data;
            
            if (lo_signal) LO <= lo_data;
            else if (lo_from_alu_signal) LO <= lo_from_alu_data;
        end
    end

    // MFSR read mux (combinational)
    always @(*) begin
        case (mfsr_sel)
            3'b000: mfsr_data = 16'h0000;  // mfz  -> ZERO
            3'b001: mfsr_data = pc;         // mfpc -> PC
            3'b010: mfsr_data = RA;         // mfra -> RA
            3'b011: mfsr_data = AT;         // mfat -> AT
            3'b100: mfsr_data = HI;         // mfhi -> HI
            3'b101: mfsr_data = LO;         // mflo -> LO
            default: mfsr_data = 16'h0000;
        endcase
    end

endmodule
