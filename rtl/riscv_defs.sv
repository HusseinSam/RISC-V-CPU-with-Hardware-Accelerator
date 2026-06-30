// rtl/riscv_defs.sv
`ifndef RISCV_DEFS_SV
`define RISCV_DEFS_SV

// Opcodes
`define OPCODE_RTYPE  7'b0110011
`define OPCODE_ITYPE  7'b0010011
`define OPCODE_LOAD   7'b0000011
`define OPCODE_STORE  7'b0100011
`define OPCODE_BRANCH 7'b1100011
`define OPCODE_JAL    7'b1101111

// funct3
`define FUNCT3_ADD_SUB 3'b000
`define FUNCT3_BEQ     3'b000

// funct7
`define FUNCT7_ADD 7'b0000000
`define FUNCT7_SUB 7'b0100000

// ALU control
`define ALU_ADD 3'b000
`define ALU_SUB 3'b001

`endif
