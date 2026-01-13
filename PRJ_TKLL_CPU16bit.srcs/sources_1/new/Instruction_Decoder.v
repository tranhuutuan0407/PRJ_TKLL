`timescale 1ns / 1ps
module Instruction_Decoder(
    input  wire [15:0] instruction,
    input  wire        reg_dst,
    output wire [3:0]  opcode,
    output wire [2:0]  funct3,
    output wire [2:0]  rs,      // ?ã qua x? lý logic ch?n (Final Rs)
    output wire [2:0]  rt,      // ?ã qua x? lý logic ch?n (Final Rt)
    output wire [2:0]  rd,      // ?ã qua Mux reg_dst
    output wire [2:0]  rs_raw,  // Cho debugging ho?c các module khác n?u c?n
    output wire [2:0]  rt_raw,
    output wire [5:0]  imm6,
    output wire [11:0] addr12
);

    // C?t bit c? b?n
    assign opcode   = instruction[15:12];
    assign rs_raw   = instruction[11:9];  // rs luôn ? ?ây
    assign rt_raw   = instruction[8:6];   // rt luôn ? ?ây
    assign funct3   = instruction[2:0];
    assign imm6     = instruction[5:0];
    assign addr12   = instruction[11:0];

    wire [2:0] rd_raw = instruction[5:3];

    // Logic xác ??nh R-Type ?? ch?n ?úng bit (theo logic c? c?a em)
    // L?u ý: Th?c t? Spec MIPS 16 này rs/rt v? trí c? ??nh, nh?ng ta gi? logic này
    // ?? ??m b?o "99% chính xác" v?i code c?.
    localparam [3:0] OP_ALU0 = 4'b0000;
    localparam [3:0] OP_ALU1 = 4'b0001;
    localparam [3:0] OP_ALU2 = 4'b0010;
    localparam [3:0] OP_MFSR = 4'b1010;
    localparam [3:0] OP_MTSR = 4'b1011;

    wire is_rtype = (opcode == OP_ALU0) || (opcode == OP_ALU1) ||
                    (opcode == OP_ALU2) || (opcode == OP_MFSR) ||
                    (opcode == OP_MTSR);

    // I-Type fields logic (dù v? trí bit rs/rt gi?ng h?t R-type trong spec này,
    // nh?ng ta v?n gi? logic mux này n?u spec thay ??i sau này)
    assign rs = is_rtype ? rs_raw : rs_raw; 
    assign rt = is_rtype ? rt_raw : rt_raw;

    // Mux ch?n thanh ghi ?ích (Rd hay Rt)
    assign rd = reg_dst ? rd_raw : rt_raw;

endmodule