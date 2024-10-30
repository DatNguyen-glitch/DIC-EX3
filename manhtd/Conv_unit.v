module Conv_unit(

input wire [15:0] data0,
input wire [15:0] data1,
input wire [15:0] data2,
input wire [15:0] data3,
input wire [15:0] data4,
input wire [15:0] data5,
input wire [15:0] data6,
input wire [15:0] data7,
input wire [15:0] data8,

input wire [15:0] weight0,
input wire [15:0] weight1,
input wire [15:0] weight2,
input wire [15:0] weight3,
input wire [15:0] weight4,
input wire [15:0] weight5,
input wire [15:0] weight6,
input wire [15:0] weight7,
input wire [15:0] weight8,

output wire [35:0] sum_final
);

/* Define wire for the non-pipeline conv */

wire [31:0] product [0:8];
wire [35:0] sum_level_1 [0:3];
wire [35:0] sum_level_2 [0:1];
wire [35:0] sum_level_3;

wire [15:0] data [0:8];
wire [15:0] weight [0:8];

/* convert input to an array */

	assign product[0] = weight0 * data0;
	assign product[1] = weight1 * data1;
	assign product[2] = weight2 * data2;
	assign product[3] = weight3 * data3;
	assign product[4] = weight4 * data4;
	assign product[5] = weight5 * data5;
	assign product[6] = weight6 * data6;
	assign product[7] = weight7 * data7;
	assign product[8] = weight8 * data8;

	assign sum_level_1[0] = product[0] + product[1];
	assign sum_level_1[1] = product[2] + product[3];
	assign sum_level_1[2] = product[4] + product[5];
	assign sum_level_1[3] = product[6] + product[7];

	assign sum_level_2[0] = sum_level_1[0] + sum_level_1[1];
	assign sum_level_2[1] = sum_level_1[2] + sum_level_1[3];
	assign sum_level_3 = sum_level_2[0] + sum_level_2[1];
	assign sum_final = product[8] + sum_level_3;

endmodule
