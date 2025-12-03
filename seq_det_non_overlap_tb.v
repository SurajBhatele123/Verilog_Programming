`timescale 1ns/1ps
`include "seq_det_non_overlap.v"

module seq_dect_1010_tb ();

reg clk;
reg rst;
reg data_in;
wire out;

seq_dect_1010 dut(.clk(clk),.rst(rst),.data_in(data_in),.out(out));
    
initial clk = 0;
always #5 clk = ~clk; // 100Mhz clock 

initial begin
    $dumpfile("seq_Dect_1010.vcd");
    $dumpvars(0,seq_dect_1010_tb);
    #5 data_in = 1;
    #5 rst = 0;
    #5 rst = 1;
    #10 data_in = 0;
    #10 data_in = 1;
    #10 data_in = 0;
    #10 data_in = 1;
    #10 data_in = 1;
    #10 data_in = 0;
    #10 data_in = 0;
    #10 data_in = 0;
    #10 data_in = 1;
    #10 data_in = 0;
    #10 data_in = 1;
    #10 data_in = 0;
    #10 data_in = 1;
    #10 data_in = 0;

    #300 $finish;

end
endmodule