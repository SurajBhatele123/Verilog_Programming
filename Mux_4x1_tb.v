`timescale 1ns/1ps
`include "Mux_4x1.v"


module Mux_4x1_tb();
    reg [3:0]x;
    reg [1:0]s;
    wire y;

Mux_4x1 dut(.I(x),.S(s),.Y(y));

reg clk;
always #100 clk = ~clk;

initial begin
    clk = 0;
       $dumpfile("Mux_4x1.vcd");
       $dumpvars(0,Mux_4x1_tb);
       
    for (integer n = 0 ;n<2**6; n=n+1) begin
        {s,x}=n;
        #2;
        
    end

       
    $finish;
    

end


endmodule