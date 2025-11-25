`timescale 1ns/1ps
`include "full_adder.v"

module Full_Adder_tb;

reg a,b,cin;
wire sum,carry;

Full_Adder uut (.a(a), .b(b), .cin(cin), .carry(carry), .sum(sum));

integer i;

initial begin
    $dumpfile("Full_Adder.vcd");
    $dumpvars(0, Full_Adder_tb);

    for(i = 0 ; i < 8 ; i = i + 1) begin
        {a,b,cin} = i;
        #10;
    end

    $finish;
end
    
endmodule
