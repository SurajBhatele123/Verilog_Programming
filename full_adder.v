module Full_Adder(
    input a,b,cin,
    output sum,carry

);

wire w1,c1,c2,c3,c4;

    xor(w1,a,b);   
    xor(sum,w1,cin);
    and(c1,a,b);
    and(c2,b,cin);
    and(c3,cin,a);
    or(c4,c1,c2);
    or(carry,c4,c3);
    

    endmodule