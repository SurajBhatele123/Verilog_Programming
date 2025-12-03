`timescale 1ns/1ps
`include "TLC.v"
module TLC_tb ();
    reg clk;
    wire [0:2] light;


TLC DUT(.clk(clk),.light(light));

initial clk = 0;
always #5 clk = ~clk;   // 100 Mhz clock 

initial begin 
    $dumpfile("TLC.vcd");
    $dumpvars(0,TLC_tb);

    #100 $finish;

end

endmodule