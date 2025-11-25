`timescale 1ns/1ps
`include "and_gate.v"

module And_Gate_tb();
reg x,y;
wire z;

And_Gate dut (.A(x),.B(y),.C(z));

reg clk;
always #5 clk = ~clk;

initial begin
    
    clk = 0;
    $dumpfile("And_Gate.vcd");
    $dumpvars(0,And_Gate_tb);

    x = 0; y = 0;
    #10 x = 0; y = 1;
    #10 x = 1; y = 0;
    #10 x = 1; y = 1;

    $finish;

end

endmodule