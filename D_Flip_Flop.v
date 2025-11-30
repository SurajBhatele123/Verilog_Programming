module D_Flip_Flop (
 input clk,
 input rst,
 input data,
 output reg q
);

always @(posedge clk) begin
    if(rst)
     q <= 1'b0;
    else
     q <= data;
end
    
endmodule