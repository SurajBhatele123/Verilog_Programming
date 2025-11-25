`timescale 1ns/1ps
`include "Mux_2x1.v"

module Mux_2x1_tb ();
reg [1:0]x;
reg Selector;
wire Y;
Mux_2x1 dut(.i(x),.sel(Selector),.y(Y));

reg clk;
always #10 clk=~clk;
initial
begin
    
    clk=0;
    $dumpfile("Mux_2x1.vcd");
    $dumpvars(0,Mux_2x1_tb);
    for(integer n = 0; n<2**3;n=n+1)begin
        {Selector,x}=n;
        #5;
    end

    //    Selector = 0 ; x[1]=0; x[0]=0;
    // #5 Selector = 0 ; x[1]=0; x[0]=1;
    // #5 Selector = 0 ; x[1]=1; x[0]=0;
    // #5 Selector = 0 ; x[1]=1; x[0]=1;
    // #5 Selector = 1 ; x[1]=0; x[0]=0;
    // #5 Selector = 1 ; x[1]=0; x[0]=1;
    // #5 Selector = 1 ; x[1]=1; x[0]=0;
    // #5 Selector = 1 ; x[1]=1; x[0]=1;

    $finish;
    
end
    
endmodule