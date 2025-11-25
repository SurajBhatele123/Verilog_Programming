// Gate Level Modeling Design
module Mux_2x1 (
    input [1:0]i,
    input sel,
    output y
);

wire selbar,w1,w2;

   not(selbar,sel);
   and(w1,selbar,i[0]);
   and(w2,sel,i[1]);
   or(y,w1,w2);
   

endmodule
