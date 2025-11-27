module full_adder(
    input a,
    input b,
    input cin,
    output sum,
    output carry
);

  assign sum = a ^ b ^ cin;
  assign carry = a & b | b & cin | cin & a;
    
endmodule

module Ripple_Adder(
 input wire [3:0] a,
 input wire [3:0] b,
 input wire cin,
 output cout,
 output [3:0] sum
);

wire w1, w2, w3;
full_adder f0(.a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .carry(w1));
full_adder f1(.a(a[1]), .b(b[1]), .cin(w1), .sum(sum[1]), .carry(w2));
full_adder f2(.a(a[2]), .b(b[2]), .cin(w2), .sum(sum[2]), .carry(w3));
full_adder f3(.a(a[3]), .b(b[3]), .cin(w3), .sum(sum[3]), .carry(cout));

endmodule