// rtl/imm_gen.sv
`include "riscv_defs.sv"

module imm_gen(
    input  logic [31:0] instr,
    output logic [31:0] imm
);

    wire [6:0] opcode = instr[6:0];

    always_comb begin
        case (opcode)

            // I-type (ADDI, LW)
            `OPCODE_ITYPE,
            `OPCODE_LOAD: begin
                imm = {{20{instr[31]}}, instr[31:20]};
            end

            // S-type (SW)
            `OPCODE_STORE: begin
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            // B-type (BEQ)
            `OPCODE_BRANCH: begin
                imm = {{19{instr[31]}},
                       instr[31],
                       instr[7],
                       instr[30:25],
                       instr[11:8],
                       1'b0};
            end

            // J-type (JAL)
            `OPCODE_JAL: begin
                imm = {{11{instr[31]}},
                       instr[31],
                       instr[19:12],
                       instr[20],
                       instr[30:21],
                       1'b0};
            end
            7'b0110111: begin // LUI
            imm = {instr[31:12], 12'b0};
            end

            default: imm = 32'b0;
        endcase
    end

endmodule
