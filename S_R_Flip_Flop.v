module S_R_Flip_Flop(
    input S,    // set input 
    input R,    // Reset Input
    input clk,  // Clock 
    input rst,  // System Reset
    output reg q  // Output 
);

always @(posedge clk) begin    // psotive edage triggered 
    if(rst)                    // reset is high
    q <= 1'b0;                 //   q is zero 
    else begin
    case({S,R})
      2'b00 : q <= q;          // Data is same 
      2'b01 : q <= 1'b0;       //  again zero
      2'b10 : q <= 1'b1;       //  again 1 
      2'b11 : q <= 1'bz;       // high impedence
      default : q <= 1'bx;

    endcase
    end
end
    
endmodule