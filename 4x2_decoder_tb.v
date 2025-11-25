`timescale 1ps/1ps
`include "4x2_decoder.v"

module decoder_2x4_tb();

reg [1:0] sel;
wire [3:0] data;

decoder_2x4 dut (sel, data);

initial begin
    $dumpfile("Decoder_2x4.vcd");
    $dumpvars(0, decoder_2x4_tb);

    for (integer i = 0; i < 2**2; i = i + 1) begin
        sel = i;
        #10;
    end

    #150 $finish;
end

endmodule
