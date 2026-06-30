// rtl/data_mem.sv
module data_mem(
    input  logic        clk,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata
);
	
    logic [31:0] mem [0:255];

    // Read (combinational)
    always_comb begin
        if (mem_read)
            rdata = mem[addr[9:2]];
        else
            rdata = 32'b0;
    end

    // Write (sequential)
    always_ff @(posedge clk) begin
        if (mem_write)
            mem[addr[9:2]] <= wdata;
    end

endmodule
