`timescale 1ns/1ps
`include "counter_4_bit.v"

module counter_4_bit_tb();

reg clk;
reg rst;
wire [3:0] count;

counter_4_bit dut(.clk(clk),.rst(rst),.count(count));

initial clk = 0;
always #5 clk = ~clk;

initial begin
    $dumpfile("Count_4_bit.vcd");
    $dumpvars(0,counter_4_bit_tb);
    rst = 1;
    #10 rst = 0;

    #200 $finish;
end
endmodule
