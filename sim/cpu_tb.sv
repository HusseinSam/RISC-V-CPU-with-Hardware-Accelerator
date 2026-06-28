// tb/cpu_tb.sv  -  Accelerator Test (N=64)
module cpu_tb;
    logic clk = 0;
    logic rst = 1;
    cpu_top dut (
        .clk(clk),
        .rst(rst)
    );
    always #5 clk = ~clk;
    integer pass_count = 0;
    integer fail_count = 0;
    integer i;
    task check;
        input [31:0] got;
        input [31:0] expected;
        input [127:0] label;
        begin
            if (got === expected) begin
                $display("  PASS  %s : got %0d (0x%08h)", label, got, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  %s : expected %0d, got %0d (0x%08h)", label, expected, got, got);
                fail_count = fail_count + 1;
            end
        end
    endtask
    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0, dut);
        // Hold reset for 2 cycles
        @(posedge clk); @(posedge clk);
        rst = 0;
        // Loop-based program: setup + 64 loop iterations + accelerator FSM
        // (~6 + 64*9 + accel setup + 4*64+5 acc cycles) -> plenty of margin
        repeat (1500) @(posedge clk);
        $display("\n========== Accelerator Test Results ==========");
        $display("  Program: dot(A,B) where A[i]=i+1, B[i]=64-i, i=0..63");
        $display("  Expected result: 45760");
        $display("----------------------------------------------");
        // Spot-check a few memory locations instead of all 128 words
        check(dut.DMEM.mem[0],   32'd1,   "mem[0]  =A[0] ");
        check(dut.DMEM.mem[1],   32'd2,   "mem[1]  =A[1] ");
        check(dut.DMEM.mem[63],  32'd64,  "mem[63] =A[63]");
        check(dut.DMEM.mem[64],  32'd64,  "mem[64] =B[0] ");
        check(dut.DMEM.mem[65],  32'd63,  "mem[65] =B[1] ");
        check(dut.DMEM.mem[127], 32'd1,   "mem[127]=B[63]");
        // Check accelerator result was read into registers
        check(dut.RF.regs[3],  32'd45760, "x3=result ");
        check(dut.RF.regs[4],  32'd1,     "x4=done   ");
        // Check accelerator internal result directly
        check(dut.ACC.result,  32'd45760, "ACC.result");
        check(dut.ACC.done,    1'b1,      "ACC.done  ");
        $display("----------------------------------------------");
        $display("  Total: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display("  ** ALL TESTS PASSED - ACCELERATOR WORKS! **");
        else
            $display("  ** SOME TESTS FAILED **");
        $display("==============================================\n");
        $finish;
    end
endmodule
