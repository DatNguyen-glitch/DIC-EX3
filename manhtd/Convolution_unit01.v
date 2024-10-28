module Convolution_unit01(
//input
data,
weight,
//output
result
);

/* Define wire for the non-pipeline conv */

input wire [16:0] data[0:9];
input wire [16:0] weight[0:9];

wire [32:0] product [0:8];
wire [36:0] sum_level_1 [0:3];
wire [36:0] sum_level_2 [0:1];
wire [36:0] sum_level_3;
wire [36:0] sum_final;

/* Multipler description */
	for (i=0; i<9; i=i+1)
		product[i] = weight [i] * data[i];

	for (i=0; i<4; i=i+1)
		sum_level_1[i] = product[2*i] + product[2*i+1];

	sum_level_2[0] = sum_level_1[0] + sum_level_1[1];
	sum_level_2[1] = sum_level_1[2] + sum_level_1[3];
	sum_level_3 = sum_level_2[0] + sum_level_2[1];
	sum_final = sum_level_1[8] + sum_level_3;

endmodule
