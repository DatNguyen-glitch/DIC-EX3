
`include "../verif/Conv_unit.v"
`include "../verif/Conv_fsm.v"
`include "../verif/register_arr.v"

module Convolution_without_pipeline(
//input
clk,
rst_n,
in_valid,
In_IFM,
In_Weight,
//output
reg_conv_out,
out_valid,
Out_OFM

);

input clk, rst_n, in_valid;
input [15:0]In_IFM;
input [15:0]In_Weight;

/* The output port should be registers */
output reg_conv_out;
output reg out_valid;
output reg[35:0] Out_OFM;
/*-------------------------------------------------------------------*/


/*  2 Input Buffer Resigter	 */
/* You have to use these buffers for the 3-1 */
reg [15:0] IFM_Buffer [0:195] ;   	/*  Use this buffer to store IFM 	*/
reg [15:0] Weight_Buffer [0:8];  		/*  Use this buffer to store Weight	*/
/*-------------------------------------------------------------------*/
/* Define inner wires for module Convolution_without_pipeline */
wire [35:0] conv_out;
wire [1:0] conv_state;

/* Define inner register for module Convolution_without_pipeline */
reg [35:0] reg_conv_out;
reg [35:0] buf_conv_out [0:12][0:12];
reg [8:0] conv_cnt_out;
reg conv_valid;

reg [36:0] reg_max_pool_in [0:3];
reg [36:0] reg_max_pool_out;


/* Define counter reg to stop data loading in */
reg [7:0] count_data;	// Data loading counter
reg [3:0] conv_cnt_line;	// Data loading counter
reg [1:0] conv_cnt_skip;	// Data loading counter

/*-------------------------------------------------------------------*/
/* Define interger and parameter */
integer i;
parameter LOAD = 2'b00, EXE = 2'b01, WAIT = 2'b10;


/* Loading 9 weights */ 
/*-------------------------------------------------------------------*/

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i=0; i<9; i=i+1)
			Weight_Buffer[i] <= 0;
	end
	else if(in_valid && count_data < 9)
		Weight_Buffer[count_data] <= In_Weight;
end

/*-------------------------------------------------------------------*/
/* Loading the 32 input datas 16-bit at by shifting Reg by Reg */


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        count_data <= 0;
        for (i = 0; i < 32; i = i + 1)
            IFM_Buffer[i] <= 0;
    end
    else begin
        if (count_data < 196) begin
            IFM_Buffer[31] <= In_IFM;
            count_data <= count_data + 1;
        end
        else begin
            IFM_Buffer[31] <= 0;
            count_data <= count_data;
        end
    end
end

genvar j;
generate
    for (j = 0; j < 31; j = j + 1) begin : shift_buffer
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n)
                IFM_Buffer[j] <= 0;
            else
                IFM_Buffer[j] <= IFM_Buffer[j + 1];
        end
    end
endgenerate


Conv_unit	u_Conv01 (
	.data0(IFM_Buffer[0]),
	.data1(IFM_Buffer[1]),
	.data2(IFM_Buffer[2]),
	.data3(IFM_Buffer[14]),
	.data4(IFM_Buffer[15]),
	.data5(IFM_Buffer[16]),
	.data6(IFM_Buffer[28]),
	.data7(IFM_Buffer[29]),
	.data8(IFM_Buffer[30]),

	.weight0(Weight_Buffer[0]),
	.weight1(Weight_Buffer[1]),
	.weight2(Weight_Buffer[2]),
	.weight3(Weight_Buffer[3]),
	.weight4(Weight_Buffer[4]),
	.weight5(Weight_Buffer[5]),
	.weight6(Weight_Buffer[6]),
	.weight7(Weight_Buffer[7]),
	.weight8(Weight_Buffer[8]),

	.conv_out(conv_out)
	);

Conv_fsm 	u_fsm01 (
    .clk(clk),
    .rst_n(rst_n),
	.count_data(count_data), 
	.count_line(conv_cnt_line), 
	.count_skip(conv_cnt_skip), 
    .state(conv_state)
);

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)	begin
		conv_cnt_line <= 4'b0000;
		conv_cnt_skip <= 2'b00;
		reg_conv_out <= 0;
	end
	else begin
		case (conv_state)
			LOAD : begin
				reg_conv_out <= reg_conv_out;
				conv_cnt_line <= conv_cnt_line;
				conv_cnt_skip <= conv_cnt_skip;
				end
			EXE : begin
				reg_conv_out <= conv_out;
				conv_cnt_line <= conv_cnt_line + 1;
				conv_cnt_skip <= 2'b00;
				end
			WAIT : begin
				reg_conv_out <= reg_conv_out;
				conv_cnt_line <= 4'b0000;
				conv_cnt_skip <= conv_cnt_skip + 1;
				end
			default : begin
				conv_cnt_line <= 4'b0000;
				conv_cnt_skip <= 2'b00;
				end
		endcase
	end
end


always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		conv_valid <= 0;
	end
	else begin
		if (conv_state == EXE) begin
			conv_valid <=1;
		end
		else begin
			conv_valid <= 0;
		end
	end
end


/*
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		out_valid <= 0;
	end
	else if (out_state == EXE) begin
			out_valid <=1;
	end
	else begin
		out_valid <= 0;
	end
end
*/

register_arr u_reg_conv (
        .clk(clk),
        .rst_n(rst_n),
        .addr_row(write_addr_row),
        .addr_col(write_addr_col),
        .data_in(data_in),
        .write_en(write_enable),
        .read_en(read_enable),
        .data_out(data_out)
    );
endmodule
