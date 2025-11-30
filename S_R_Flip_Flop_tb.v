// ...existing code...
`timescale 1ps/1ps
`include "S_R_Flip_Flop.v"

module S_R_Flip_Flop_tb();
reg S, R, clk, rst;
wire q;

S_R_Flip_Flop dut (.S(S), .R(R), .clk(clk), .q(q));

initial clk = 0;
always #5 clk = ~clk;

initial begin 
    $dumpfile("S_R_Flip_Flop.vcd");
    $dumpvars(0, S_R_Flip_Flop_tb);
    #10
     rst = 1;
     #10 rst = 0;
     #10 S = 0; R = 0;
     #10 S = 0; R = 1;
     #10 S = 1; R = 0;
     #10 S = 1; R = 1;
  #100 $finish;
    end 

    
endmodule
