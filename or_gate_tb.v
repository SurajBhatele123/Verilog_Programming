`timescale  1ns/1ps
`include "or_gate.v"

module or_gate_tb () ;
    reg a,b;
    wire y;

or_gate dut (.a(a),.b(b),.y(y));

initial begin 
    $dumpfile("or_gate.vcd");
    $dumpvars(0,or_gate_tb);

    for (integer i = 0; i<2**2;i=i+1) begin
        {a,b}=i;
        #5;
    end

    $finish;
end
endmodule