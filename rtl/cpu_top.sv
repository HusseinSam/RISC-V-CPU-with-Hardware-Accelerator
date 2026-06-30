// rtl/cpu_top.sv
module cpu_top (
    input  logic        clk,
    input  logic        rst,
    output logic [31:0] debug_pc,
    output logic [31:0] debug_result
);

    // Address Map:
    // 0x0000_0000 - 0x0000_FFFF : Data Memory
    // 0x8000_0000 - 0x8000_00FF : Accelerator

    // =====================
    // Program Counter
    // =====================
    logic [31:0] pc, pc_next;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'b0;
        else
            pc <= pc_next;
    end

    // =====================
    // Instruction Memory
    // =====================
    logic [31:0] imem [0:255];
    logic [31:0] instr;

    initial $readmemh("program.hex", imem);
    assign instr = imem[pc[9:2]];

    // =====================
    // Decode Fields
    // =====================
    logic [6:0] opcode;
    logic [4:0] rd, rs1, rs2;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    // =====================
    // Control Signals
    // =====================
    logic reg_write, alu_src, mem_read, mem_write, mem_to_reg;
    logic branch, jump;
    logic [2:0] alu_ctrl;

    control_unit CU (
        .opcode    (opcode),
        .funct3    (funct3),
        .funct7    (funct7),
        .reg_write (reg_write),
        .alu_src   (alu_src),       // FIX: now connected
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .mem_to_reg(mem_to_reg),    // FIX: now connected
        .branch    (branch),
        .jump      (jump),
        .alu_ctrl  (alu_ctrl)
    );

    // =====================
    // Register File
    // =====================
    logic [31:0] rs1_data, rs2_data, wb_data;

    regfile RF (
        .clk(clk),
        .we (reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd (rd),
        .wd (wb_data),
        .rd1(rs1_data),
        .rd2(rs2_data)
    );

    // =====================
    // Immediate Generator
    // =====================
    logic [31:0] imm;

    imm_gen IMM (
        .instr(instr),
        .imm  (imm)
    );

    // =====================
    // ALU
    // FIX: use alu_src from control unit instead of manual (mem_read||mem_write)
    // This correctly covers ADDI as well as LW/SW
    // =====================
    logic [31:0] alu_out;
    logic        zero;

    alu ALU (
        .a       (rs1_data),
        .b       (alu_src ? imm : rs2_data),  // FIX: driven by alu_src
        .alu_ctrl(alu_ctrl),
        .result  (alu_out),
        .zero    (zero)
    );

    // =====================
    // Address Decode
    // =====================
    wire is_acc;
    assign is_acc = (alu_out[31:28] == 4'h8);

    // =====================
    // Accelerator Memory Interface signals
    // =====================
    logic        acc_mem_re;
    logic [31:0] acc_mem_addr;
    logic [31:0] acc_mem_rdata;

    // =====================
    // Data Memory
    // CPU or Accelerator may request a read; accelerator read takes priority
    // when the CPU is not doing a load (mem_read low).
    // =====================
    logic        dmem_re_effective;
    logic [31:0] dmem_addr_effective;
    logic [31:0] dmem_rdata;

    // Mux: accelerator read request vs CPU read request
    assign dmem_re_effective   = (mem_read  && !is_acc) ? 1'b1    : acc_mem_re;
    assign dmem_addr_effective = (mem_write && !is_acc) ? alu_out  :
                             (mem_read  && !is_acc) ? alu_out  : acc_mem_addr;

    data_mem DMEM (
        .clk      (clk),
        .mem_write(mem_write && !is_acc),
        .mem_read (dmem_re_effective),
        .addr     (dmem_addr_effective),
        .wdata    (rs2_data),
        .rdata    (dmem_rdata)
    );

    assign acc_mem_rdata = dmem_rdata;  // FIX: feed memory data back to accelerator

    // =====================
    // Accelerator
    // FIX: mem_re, mem_addr, mem_rdata are now properly connected
    // =====================
    logic [31:0] acc_rdata;

    accelerator ACC (
        .clk      (clk),
        .rst      (rst),
        .acc_we   (mem_write && is_acc),
        .acc_re   (mem_read  && is_acc),
        .acc_addr (alu_out),
        .acc_wdata(rs2_data),
        .acc_rdata(acc_rdata),
        .mem_re   (acc_mem_re),     // FIX: connected
        .mem_addr (acc_mem_addr),   // FIX: connected
        .mem_rdata(acc_mem_rdata)   // FIX: connected
    );

    // =====================
    // Writeback MUX
    // FIX: use mem_to_reg from control unit; also handle accelerator readback
    // =====================
    always_comb begin
        if (mem_to_reg) begin
            if (is_acc)
                wb_data = acc_rdata;
            else
                wb_data = dmem_rdata;
        end else if (jump) begin
            wb_data = pc + 4;  // JAL saves return address
        end else begin
            wb_data = alu_out;
        end
    end

    // =====================
    // PC Next Logic
    // =====================
    always_comb begin
        pc_next = pc + 4;

        if (branch && zero)
            pc_next = pc + imm;

        if (jump)
            pc_next = pc + imm;
    end
assign debug_pc     = pc;
assign debug_result = alu_out;
endmodule
