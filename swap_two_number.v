module swap_2_number();

reg [1:0]a,b,temp;

initial begin
    a = 2'b01;
    b = 2'b10;
end
initial
begin
    $display("Before the swapping value :- ");
    $display("a = %d , b = %d ",a,b);
end

initial begin
    temp = a;
     a = b;
     b = temp;
end

initial
begin
    $display("After the swapping Value :- ");
    $display("a = %d , b = %d ",a,b);
end
    endmodule