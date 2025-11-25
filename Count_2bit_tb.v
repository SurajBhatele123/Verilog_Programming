`timescale 1ns/1ps
`include "Counter_2bit.v"

module Counter_2bit_tb();
reg rst;
reg clk;
wire [1:0] count;

Counter_2bit dut (.rst(rst),.clk(clk),.Count(count));  

// Generation of Clock 
initial clk = 0;
always begin 
    #5 clk = ~clk;   //  clk change every 5nsec time 
end
// taken a input for the testing 

initial begin
    // $display("Time\Rest\Count");

    
    $dumpfile("Counter_2bit.vcd");
    $dumpvars(0,Counter_2bit_tb);
    rst = 1 ; 
    #10;
    rst = 0 ;
    #100
    rst = 1;
    #50;
    rst = 0;
    #20

    
    $finish;
end

// initial
//  begin 
//     $monitor("%0t\%b\%b",$time,rst,count);
//  end
endmodule
