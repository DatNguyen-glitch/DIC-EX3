// ---------------------------------------------------------------------------------------
// ---------------------LineBuffer and WindowBuffer method--------------------------------
//----------------------------------------------------------------------------------------

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
reg [2:0] state_cs, state_ns;
parameter IDLE = 3'd0;
parameter UPDATE = 3'd1;
parameter EXE = 3'd2;
reg [7:0] i = 8'b00000000;
reg [7:0] current_pooling = 8'b00000000;
//////////////The output port shoud be registers///////////////////////
output reg out_valid;
output reg[35:0] Out_OFM;
//////////////////////////////////////////////////////////////////////
reg [7:0] count = 8'b00000000;
reg [7:0] count_wait = 8'b00000000;
reg [7:0] current_IFM = 8'b00000000;
reg [7:0] current_OFM_Buffer = 8'b00000000;
reg [15:0] temp1, temp2;
reg first_convolution_done, last_convolution_done;
/////// 2 Buffer/////////////
//You have to sue these buffers for the 3-1 ///////
reg [15:0]IFM_Buffer[0:195] ;   //  Use this buffer to store IFM
reg [15:0]Weight_Buffer[0:8];  	//  Use this buffer to store Weight
reg [7:0] OFM_Buffer[0:143];	//  Use this buffer to store OFM

/////////////////////////////////////


////////Here just an example of how to use IFM_buffer & WEight_Buffer to store data////////
//The storage mechanism can be modified, but not the buffer size cannot be modified
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i=0;i<9;i=i+1)
			Weight_Buffer[i] <= 0;
		count <= 0;
	end
	else if(in_valid && (count < 9))
		Weight_Buffer[count] <= In_Weight;
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i=0;i<196;i=i+1)
			IFM_Buffer[i] <= 0;
		count <= 0;
		current_IFM <= 0;
		first_convolution_done <= 0;
		last_convolution_done <= 0;
	end
	else if(in_valid) begin
		if(count < 31) begin
			IFM_Buffer[count]  <= In_IFM;
			count <= count + 1;
		end	
	end

end
///////////////////////////////////////////////////////

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		state_cs <= EXE;		
	else
		state_cs <= state_ns;	
end
always@(*) begin                
    case(state_cs)
        EXE: //////////////                  
        begin
            if((current_IFM == 11) && (count_wait == 0))
                state_ns = UPDATE;
            else
                state_ns = EXE;
        end /////////
        UPDATE: //////////////
        begin
            if((count_wait == 2) && in_valid) begin
                state_ns = EXE;
		current_IFM <= 0;
	        end
            else
                state_ns = UPDATE;
        end
        default:
        begin                
            state_ns = EXE;
        end /////////
    endcase
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		current_IFM <= 0;
        count_wait <= 0;
	end
	else if((state_cs == UPDATE) && in_valid) begin
		for(i=0;i<30;i=i+1)
			IFM_Buffer[i] <= IFM_Buffer[i+1];
		IFM_Buffer[30] <= In_IFM;
		count_wait <= count_wait + 1;
		$display("count_wait): %d", count_wait);
		$display("IFM_Buffer 3x3 Matrix (count_wait):");
		$display("%d %d %d", IFM_Buffer[0], IFM_Buffer[1], IFM_Buffer[2]);
		$display("%d %d %d", IFM_Buffer[14], IFM_Buffer[15], IFM_Buffer[16]);
		$display("%d %d %d", IFM_Buffer[28], IFM_Buffer[29], IFM_Buffer[30]);
		$display("%d %d %d %d %d %d %d %d %d %d %d %d %d %d ",IFM_Buffer[0],IFM_Buffer[1],IFM_Buffer[2],IFM_Buffer[3],IFM_Buffer[4],
									IFM_Buffer[5],IFM_Buffer[6],IFM_Buffer[7],IFM_Buffer[8],IFM_Buffer[9],
									IFM_Buffer[0],IFM_Buffer[0],IFM_Buffer[0],IFM_Buffer[13]);
		$display("%d %d %d %d %d %d %d %d %d %d %d %d %d %d ",IFM_Buffer[14],IFM_Buffer[15],IFM_Buffer[16],IFM_Buffer[17],IFM_Buffer[18],
									IFM_Buffer[19],IFM_Buffer[20],IFM_Buffer[21],IFM_Buffer[22],IFM_Buffer[23],
									IFM_Buffer[24],IFM_Buffer[25],IFM_Buffer[26],IFM_Buffer[27]);
		$display("%d %d %d %d",IFM_Buffer[28],IFM_Buffer[29],IFM_Buffer[30],IFM_Buffer[31]);	
	end
end

///////////////////////////////////////////////////////
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		out_valid <= 0;
	else if(last_convolution_done == 1)
		out_valid <= 1;
	else
		out_valid <= 0;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i=0;i<143;i=i+1)
			OFM_Buffer[i] <= 0;
	end
	else if((count > 30) && (state_cs == EXE) && in_valid) begin
		$display("IFM_Buffer 3x3 Matrix:");
		$display("%d %d %d", IFM_Buffer[0], IFM_Buffer[1], IFM_Buffer[2]);
		$display("%d %d %d", IFM_Buffer[14], IFM_Buffer[15], IFM_Buffer[16]);
		$display("%d %d %d", IFM_Buffer[28], IFM_Buffer[29], IFM_Buffer[30]);	

		OFM_Buffer[current_OFM_Buffer] <= IFM_Buffer[0]*Weight_Buffer[0]			// 3x3 convolution
				  +IFM_Buffer[1]*Weight_Buffer[1]
				  +IFM_Buffer[2]*Weight_Buffer[2]
				  +IFM_Buffer[14]*Weight_Buffer[3]
				  +IFM_Buffer[15]*Weight_Buffer[4]
				  +IFM_Buffer[16]*Weight_Buffer[5]
				  +IFM_Buffer[28]*Weight_Buffer[6]
				  +IFM_Buffer[29]*Weight_Buffer[7]
				  +IFM_Buffer[30]*Weight_Buffer[8];	
		current_OFM_Buffer <= current_OFM_Buffer + 1;
	    	current_IFM <= current_IFM + 1;
		count_wait <= 0;
	    	$display("current_IFM: %d ", current_IFM);
		if(current_IFM < 11) begin
			for(i=0;i<30;i=i+1)
				IFM_Buffer[i] <= IFM_Buffer[i+1];
			IFM_Buffer[30] <= In_IFM;
		end
		$display("IFM Buffer:");		
		$display("%d %d %d %d %d %d %d %d %d %d %d %d %d %d ",IFM_Buffer[0],IFM_Buffer[1],IFM_Buffer[2],IFM_Buffer[3],IFM_Buffer[4],
									IFM_Buffer[5],IFM_Buffer[6],IFM_Buffer[7],IFM_Buffer[8],IFM_Buffer[9],
									IFM_Buffer[0],IFM_Buffer[0],IFM_Buffer[0],IFM_Buffer[13]);
		$display("%d %d %d %d %d %d %d %d %d %d %d %d %d %d ",IFM_Buffer[14],IFM_Buffer[15],IFM_Buffer[16],IFM_Buffer[17],IFM_Buffer[18],
									IFM_Buffer[19],IFM_Buffer[20],IFM_Buffer[21],IFM_Buffer[22],IFM_Buffer[23],
									IFM_Buffer[24],IFM_Buffer[25],IFM_Buffer[26],IFM_Buffer[27]);
		$display("%d %d %d %d",IFM_Buffer[28],IFM_Buffer[29],IFM_Buffer[30],IFM_Buffer[31]);
		if(current_OFM_Buffer == 143) begin
			last_convolution_done <= 1;
			for(i=0;i<144;i=i+1)
				$display("%d ", OFM_Buffer[i]);
		end
	end
	else begin
		for (i=0;i<144;i=i+1)
			OFM_Buffer[i] <= 0;
	end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Out_OFM <= 0;
    end
    else if(last_convolution_done == 1) begin
		Out_OFM <= max_pooling(
                    OFM_Buffer[current_pooling],
                    OFM_Buffer[current_pooling + 1],
                    OFM_Buffer[current_pooling + 12],
                    OFM_Buffer[current_pooling + 13]);
		current_pooling <= current_pooling + 2;
		if(is_divisible_by_12(current_pooling+2)) begin
			current_pooling <= current_pooling + 14;
		end
    end
end
function is_divisible_by_12;
    input [7:0] num;
    begin
        is_divisible_by_12 = (num / 12) * 12 == num;
    end
endfunction
function [7:0] max_pooling;
    input [7:0] a, b, c, d;
    begin
        max_pooling = (a > b) ? a : b;
        max_pooling = (max_pooling > c) ? max_pooling : c;
        max_pooling = (max_pooling > d) ? max_pooling : d;
    end
endfunction
endmodule
