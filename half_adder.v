module half_adder (
    input a,
    input b,
    output  Sum,
    output  Carry
);

    assign sum = a^b;
    assign carry = a&b;

endmodule