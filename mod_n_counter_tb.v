`timescale 1ns/1ps
`include "mod_n_counter.v"

module mod_n_counter_tb;
    // parameters for the testbench
    parameter N = 6; // total number of states
    parameter W = 4; // number of bits (width of q)

    reg clk;
    reg rst;
    wire [W-1:0] q;

    // Instantiate DUT with parameters (if your DUT has the same parameter names)
    mod_n_counter #(
        .N(N),
        .W(W)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .q(q)
    );

    // 10 ns clock period (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("mod_n_counter.vcd");
        $dumpvars(0, mod_n_counter_tb);

        // Apply reset pulse (hold for a bit more than one clock cycle)
        rst = 1;
        #12;
        rst = 0;

        // Run for enough cycles to observe counting and wrap-around
        // (each clock period is 10 ns, so (N+4)*10 gives a few extra cycles)
        #((N + 4) * 10);

        $finish;
    end
endmodule



