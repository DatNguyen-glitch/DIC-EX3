
module max_pooling (
    input [35:0] conv_val0,
    input [35:0] conv_val1,
    input [35:0] conv_val2,
    input [35:0] conv_val3,
    output [35:0] max_val
);
	wire [35:0] max_br1;
	wire [35:0] max_br2;

	

    assign max_br1 = (conv_val0 > conv_val1) ? conv_val0 : conv_val1;
    assign max_br2 = (conv_val2 > conv_val3) ? conv_val2 : conv_val3;

    assign max_val = (max_br1 > max_br2) ? max_br1 : max_br2;

endmodule

