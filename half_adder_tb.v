`timescale 1ns/1ps
`include "half_adder.v"


module half_adder_tb ();
    reg x,y;
    wire sum,carry;

half_adder dut (.a(x),.b(y),.Sum(sum),.Carry(carry));

initial begin
    
    $dumpfile("half_adder.vcd");
    $dumpvars(0,half_adder_tb);

    for(integer i = 0; i<2**2;i=i+1) 
    begin
        {x,y}=i;
        #5;
    end
    
    $finish;
end
    
endmodule