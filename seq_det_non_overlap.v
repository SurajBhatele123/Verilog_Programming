module seq_dect_1010 (input clk , input rst , input data_in, output reg out );
parameter S0 = 4'h1;
parameter S1 = 4'h2;
parameter S2 = 4'h3;
parameter S3 = 4'h4;
parameter S4 = 4'h5;

reg [3:0] state, next_state;

always @(posedge clk or negedge rst ) begin  // this is for check states only 
    if(!rst)
       state = S0;
    else
       state <= next_state;
end

always @(state or data_in) begin
    case(state)
    S0: begin if(data_in == 0 ) next_state = S0;
    else next_state = S1; end
    S1: begin if(data_in == 0) next_state = S2;
        else next_state = S1; end
    S2: begin if(data_in == 0) next_state = S0;
    else next_state = S3; end
    S3: begin if(data_in == 0 ) next_state = S4;
    else next_state = S1; end
    S4: begin if(data_in == 0 ) next_state = S0;
    else next_state = S1; end
    default : next_state = S0;

    endcase
end

always @(state) begin
    case(state)
    S0: out = 0;
    S1: out = 0;
    S2: out = 0;
    S3: out = 0;
    S4: out = 1;
    default : out = 0;
     endcase
end
endmodule