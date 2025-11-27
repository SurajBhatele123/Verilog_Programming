`timescale 1ns/1ps
`include "Ripple_adder.v"

module Ripple_Adder_tb();
reg [3:0] a;
reg [3:0] b;
reg cin;
wire cout;
wire [3:0] sum;

Ripple_Adder dut (.a(a), .b(b), .cout(cout), .sum(sum), .cin(cin));

initial begin
    $dumpfile("Ripple_Adder.vcd");
    $dumpvars(0, Ripple_Adder_tb);

    for (integer i = 0; i < 2**4; i = i + 1) begin
        {a, b, cin} = i;
        #10;
    end

    $finish;
end

initial begin
    $monitor("Time=%0t | A=%b | B=%b | cin=%b | cout=%b | sum=%b", 
             $time, a, b, cin, cout, sum);
end

endmodule