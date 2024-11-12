
`include "../01_RTL/Conv_unit_pipeline.v"
`include "../01_RTL/line_buffer.v"
`include "../01_RTL/Conv_fsm.v"
`include "../01_RTL/pooling.v"
`include "../01_RTL/RegisterArray.v"

module Convolution_optimize(
	//input
clk,
rst_n,
in_valid,
In_IFM,
In_Weight,
//output
out_valid,
Out_OFM

);

input clk, rst_n, in_valid;
input [15:0]In_IFM;
input [15:0]In_Weight;

//////////////The output port shoud be registers///////////////////////
output reg out_valid;
output reg[35:0] Out_OFM;
//////////////////////////////////////////////////////////////////////
reg [7:0] count_load;
reg [15:0] Weight_Buffer[0:8];  
wire [15:0] data [0:8];
wire [35:0] conv_out;
wire [1:0] conv_state;
reg [35:0] reg_conv_out;
reg [7:0] count_conv;


integer i;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i=0;i<9;i=i+1)
			Weight_Buffer[i] <= 0;
	end
	else if(in_valid && (count_load < 'd9))
		Weight_Buffer[count_load] <= In_Weight;
end


always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count_load <= 8'd0;
	end
	else if(in_valid && (count_load < 8'd196)) begin
		count_load <= count_load +1;
	end
	else if(conv_state == 2'b11)begin
		count_load <= 8'd0;	
	end	
	else begin
		count_load <= count_load;
	end
end


line_buffer u_ln_buf (
	.clk(clk),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.In_IFM(In_IFM),
	.data0(data[0]),
	.data1(data[1]),
	.data2(data[2]),
	.data3(data[3]),
	.data4(data[4]),
	.data5(data[5]),
	.data6(data[6]),
	.data7(data[7]),
	.data8(data[8])
);

Conv_unit_pipeline	u_conv (
	.clk(clk),
	.rst_n(rst_n),
	.data0(data[0]),
	.data1(data[1]),
	.data2(data[2]),
	.data3(data[3]),
	.data4(data[4]),
	.data5(data[5]),
	.data6(data[6]),
	.data7(data[7]),
	.data8(data[8]),

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

Conv_fsm u_conv_fsm (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .count_load(count_load),
    .state(conv_state)
);

wire [35:0] max_pool;
reg mem_pool_rd_en [0:1];
reg [7:0] reg_mem_pool_wr_addr;
reg [7:0] reg_mem_pool_rd_addr;

wire [35:0] mem_pool_val;
wire mem_pool_wr_en;
wire [7:0] mem_pool_addr;

pooling u_pool(
.clk(clk), 
.rst_n(rst_n),
.conv_state(conv_state),
.conv_val(conv_out),
.write_en(mem_pool_wr_en),
.pool_val(max_pool)
);

assign mem_pool_addr = mem_pool_wr_en ? reg_mem_pool_wr_addr : reg_mem_pool_rd_addr;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		reg_mem_pool_wr_addr <= 8'd0;
	end
	else if(mem_pool_wr_en) begin
		reg_mem_pool_wr_addr <= reg_mem_pool_wr_addr + 8'd1;
	end
	else if(conv_state == 2'b00) begin
		reg_mem_pool_wr_addr <= 8'd0;
	end
	else begin
		reg_mem_pool_wr_addr <= reg_mem_pool_wr_addr;
	end
end

parameter DEL_SZ = 2;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		mem_pool_rd_en[0] <= 1'b0;
		mem_pool_rd_en[1] <= 1'b0;
	end
	else if((reg_mem_pool_wr_addr == 8'd36) && (reg_mem_pool_rd_addr < 8'd35)) begin
		mem_pool_rd_en[0] <= 1'b1;
		mem_pool_rd_en[1] <= mem_pool_rd_en[0];
	end
	else begin
		mem_pool_rd_en[0] <= 1'b0;
		mem_pool_rd_en[1] <= mem_pool_rd_en[0];
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		reg_mem_pool_rd_addr[0] <= 8'd0;
	//	Out_OFM <= 0;
	end
	else if(mem_pool_rd_en[0]) begin
		reg_mem_pool_rd_addr <= reg_mem_pool_rd_addr + 8'd1;
	//	Out_OFM <= mem_pool_val;
	end
	else if(conv_state == 2'b00) begin
		reg_mem_pool_rd_addr <= 8'd0;
	end
	else begin
		reg_mem_pool_rd_addr <= reg_mem_pool_rd_addr;
	end
end

RegisterArray #( .MEM_SZ(36) ) u_mem_pool (
	.clk(clk),
	.rst_n(rst_n),
	.addr(mem_pool_addr),
	.data_in(max_pool),
	.write_enable(mem_pool_wr_en),
	.read_enable(mem_pool_rd_en[0]),
	.data_out(mem_pool_val)
);

reg [15:0] count_clk;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count_clk <= 0;
	end
	else
		count_clk <= count_clk + 1;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 1'b0;
		Out_OFM <= 36'd0;
	end
	else if(mem_pool_rd_en[1]) begin
		out_valid <= 1'b1;
		Out_OFM <= mem_pool_val;
	end
	else begin
		out_valid <= 1'b0;
		Out_OFM <= 36'd0;
	end
end

endmodule
