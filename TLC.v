module TLC (
    input clk,
    output reg [0:2] light
);

parameter S0 = 0; parameter S1 = 1; parameter S2 = 2;
parameter RED = 3'b100 , GREEN = 3'b010 ,YELLOW = 3'b001;
reg [0:1] states;

always @(posedge clk) begin
    case(states)
    S0 : states <= S1;
    S1 : states <= S2;
    S2 : states <= S0;
    default : states <= S0;

    endcase

end

always @(states) begin
    case(states)
    S0 : light = RED;
    S1 : light = YELLOW;
    S2 : light = GREEN;
    default : states = RED;
    endcase
end

    
endmodule