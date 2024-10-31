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
parameter POOLING = 3'd3;
reg [7:0] i; 
reg [7:0] j;
reg [7:0] current_pooling;
//////////////The output port shoud be registers///////////////////////
output reg out_valid;
output reg[35:0] Out_OFM;
//////////////////////////////////////////////////////////////////////
reg [7:0] count;
reg [7:0] count_wait;
reg [7:0] count_Out_OFM;
reg [7:0] current_IFM;
reg [7:0] current_OFM_Buffer;
reg [15:0] temp1[0:31];
reg [15:0] count_clk;
reg first_convolution_done, last_convolution_done;
/////// 2 Buffer/////////////
//You have to sue these buffers for the 3-1 ///////
reg [35:0]IFM_Buffer[0:195] ;   //  Use this buffer to store IFM
reg [35:0]Weight_Buffer[0:8];  	//  Use this buffer to store Weight
reg [35:0] OFM_Buffer[0:143];	//  Use this buffer to store OFM

/////////////////////////////////////
always@(posedge clk) begin
	count_clk = count_clk + 1;
end
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
		out_valid <= 0;
		Out_OFM <= 0;
	end
	else if(in_valid) begin
		if(count < 196) begin
			IFM_Buffer[31]  <= In_IFM;
			count <= count + 1;
		end	
		else begin
			IFM_Buffer[31] <= 0;
			count <= count;
		end
	end

end

always @(posedge clk or negedge rst_n) begin
    	if (!rst_n) begin
        	for (j = 0; j < 31; j = j + 1) begin
            		IFM_Buffer[j] <= 0;
        	end
    	end 
	else begin
        	for (j = 0; j < 31; j = j + 1) begin
            	IFM_Buffer[j] <= IFM_Buffer[j + 1];
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
        IDLE: //////////////
        begin
            if(in_valid)
                state_ns <= UPDATE;
            else begin
                state_ns <= IDLE;
		current_pooling <= 0;
		count <= 0;
		count_wait <= 0;
		count_Out_OFM <= 0;
		current_IFM <= 0;
		current_OFM_Buffer <= 0;
		first_convolution_done <= 0;
		last_convolution_done <= 0;
		end
        end /////////
        POOLING: //////////////
        begin
            if(count_Out_OFM == 37) begin
                state_ns <= IDLE;
                Out_OFM <= 0;
            end
            else
                state_ns <= POOLING;
        end /////////
        EXE: //////////////                  
        begin
            if((current_IFM == 11) && (count_wait == 0) & in_valid)
                state_ns <= UPDATE;
            else if(current_OFM_Buffer == 143)
                state_ns <= POOLING;
            else
                state_ns <= EXE;
        end /////////
        UPDATE: //////////////
        begin
            if((count_wait == 1) && in_valid) begin
                state_ns <= EXE;
		current_IFM <= 0;
	        end
            else
                state_ns <= UPDATE;
        end
        default:
        begin                
            state_ns <= EXE;
        end /////////
    endcase
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		current_IFM <= 0;
        	count_wait <= 0;
	end
	else if((state_cs == UPDATE)) begin
		if(in_valid) begin
			for(i=0;i<31;i=i+1) begin
				IFM_Buffer[i] <= IFM_Buffer[i+1];
			end
			//IFM_Buffer[30] <= In_IFM;
			count_wait <= count_wait + 1;
		end
	end
end

///////////////////////////////////////////////////////
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		out_valid <= 0;
	else if(current_OFM_Buffer > 143 && count_Out_OFM < 36)
		out_valid <= 1;
	else
		out_valid <= 0;
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		Out_OFM <= 0;
	else if(out_valid == 0 && count_Out_OFM > 35)
		Out_OFM <= Out_OFM;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i=0;i<143;i=i+1)
			OFM_Buffer[i] <= 0;
	end
	else if((count > 31) && (state_cs == EXE)) begin
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
		if(current_IFM < 11) begin
			for(i=0;i<31;i=i+1)
				IFM_Buffer[i] <= IFM_Buffer[i+1];
		end
		if(current_OFM_Buffer == 144) begin
			last_convolution_done <= 1;
		end
	end
	//else begin
	//	for (i=0;i<144;i=i+1)
	//		OFM_Buffer[i] <= 0;
	//end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		Out_OFM <= 0;
	end
	else if(state_cs == POOLING) begin
		Out_OFM <= max_pooling(
                    OFM_Buffer[current_pooling],
                    OFM_Buffer[current_pooling + 1],
                    OFM_Buffer[current_pooling + 12],
                    OFM_Buffer[current_pooling + 13]);
		current_pooling <= current_pooling + 2;
		if(is_divisible_by_12(current_pooling+2)) begin
			current_pooling <= current_pooling + 14;
		end
        count_Out_OFM <= count_Out_OFM + 1;
	end
end
function is_divisible_by_12;
    input [35:0] num;
    begin
        is_divisible_by_12 = (num / 12) * 12 == num;
    end
endfunction
function [35:0] max_pooling;
    input [35:0] a, b, c, d;
    begin
        max_pooling = (a > b) ? a : b;
        max_pooling = (max_pooling > c) ? max_pooling : c;
        max_pooling = (max_pooling > d) ? max_pooling : d;
    end
endfunction
endmodule

