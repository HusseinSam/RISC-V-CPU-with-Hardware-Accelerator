module regfile(
    input  logic        clk,
    input  logic        we,
    input  logic [4:0]  rs1, rs2, rd,
    input  logic [31:0] wd,
    output logic [31:0] rd1, rd2
);

    logic [31:0] regs [31:0];

    initial begin
        for (int i = 0; i < 32; i = i + 1) begin
            regs[i] = 32'b0;
        end
    end


    assign rd1 = (rs1 == 0) ? 32'b0 : regs[rs1];
    assign rd2 = (rs2 == 0) ? 32'b0 : regs[rs2];

    always_ff @(posedge clk) begin
        if (we && rd != 0)
            regs[rd] <= wd;
    end

endmodule
