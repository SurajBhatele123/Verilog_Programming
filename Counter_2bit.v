module Counter_2bit ( 
    input clk,
    input rst,
    output reg [1:0] Count
);

 always @(posedge clk) begin
    if(rst)
       Count <= 2'b00;
    else
       Count <= Count + 1;

 end
endmodule