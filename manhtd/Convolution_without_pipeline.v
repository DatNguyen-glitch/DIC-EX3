module Convolution_without_pipeline(
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

/* The output port should be registers */
output reg out_valid;
output reg[35:0] Out_OFM;
/*-------------------------------------------------------------------*/


/*  2 Input Buffer Resigter	 */
/* You have to use these buffers for the 3-1 */
reg [15:0]IFM_Buffer[0:195] ;   	/*  Use this buffer to store IFM 	*/
reg [15:0]Weight_Buffer[0:8];  		/*  Use this buffer to store Weight	*/
/*-------------------------------------------------------------------*/

/* Define the window buffer by array of wires */
wire [15:0] dat_window [8:0];

/* Define counter reg to stop data loading in */
reg [7:0] count;	// Data loading counter

/* Here just an example of how to use IFM_buffer & WEight_Buffer to store data */
/* The storage mechanism can be modified, but not the buffer size cannot be modified */

/* Loading 9 weights */ 
/*-------------------------------------------------------------------*/
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i=0; i<9; i=i+1)
			Weight_Buffer[i] <= 0;
	end
	else if(in_valid && count < 9)
		Weight_Buffer[count] <= In_Weight;
end

/*-------------------------------------------------------------------*/
/* Loading the 32 input datas 16-bit at by shifting Reg by Reg */
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i=0; i<32; i=i+1)
			IFM_Buffer[i] <= 0;
		count <= 0;
	end

	else begin
		if (count < 196) begin
			IFM_Buffer[31] <= In_IFM;
			count <= count + 1;
		end
		else begin
			IFM_Buffer[31] <= 0;
			count <= count;
		end
		
		genvar i;
		generate
			for (i = 0; i < 31; i = i + 1) : reg_gen
				IFM_Buffer[i] <= IFM_Buffer[i+1];
		endgenerate
	end
end

/*-------------------------------------------------------------------*/
/* Mapping data to the data buffer window dat_window */

assign dat_window [0] <= IFM_buffer[0];
assign dat_window [1] <= IFM_buffer[1];
assign dat_window [2] <= IFM_buffer[2];

assign dat_window [3] <= IFM_buffer[14];
assign dat_window [4] <= IFM_buffer[15];
assign dat_window [5] <= IFM_buffer[16];

assign dat_window [6] <= IFM_buffer[28];
assign dat_window [7] <= IFM_buffer[29];
assign dat_window [8] <= IFM_buffer[30];

/*-------------------------------------------------------------------*/





endmodule
