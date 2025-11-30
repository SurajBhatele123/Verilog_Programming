`timescale 1ps/1ps
`include "D_Flip_Flop.v"

module D_Flip_Flop_tb();

reg clk;
reg rst;
reg data;
wire q;


D_Flip_Flop DUT(.clk(clk),.rst(rst),.data(data),.q(q));

initial clk = 0;
always #5 clk = ~ clk;

initial begin 

    $dumpfile("D_Flip_Flop.vcd");
    $dumpvars(0,D_Flip_Flop_tb);
     
    for(integer i = 0 ; i<2**3 ; i = i+1) begin
        {rst,data} = $random;
        #5;
end

    #100 $finish;

end

    
endmodule