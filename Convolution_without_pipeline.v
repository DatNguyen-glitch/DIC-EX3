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
parameter IN_DATA = 3'd1;
parameter EXE = 3'd2;
reg [7:0] i = 8'b00000000;
reg [7:0] current_pooling = 8'b00000000;
//////////////The output port shoud be registers///////////////////////
output reg out_valid;
output reg[35:0] Out_OFM;
//////////////////////////////////////////////////////////////////////
reg [7:0] count = 8'b00000000;
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
	else if(in_valid && (count < 196)) begin
		if(count < 32) begin
			IFM_Buffer[count]  <= In_IFM;
			count <= count + 1;
		end
		else if(first_convolution_done) begin
			for(i=0;i<30;i=i+1)
				IFM_Buffer[i] <= IFM_Buffer[i+1];
			IFM_Buffer[30] <= In_IFM;
			// temp1 = IFM_Buffer[current_IFM-1+14];		// modify value of line buffer
			// temp2 = IFM_Buffer[current_IFM-1+28];
			// IFM_Buffer[current_IFM-1] <= temp1;		
			// IFM_Buffer[current_IFM-1+14] <= temp2;
			// IFM_Buffer[current_IFM-1+28] <= In_IFM;
			// $display("IFM_Buffer 3x14 Matrix:");
			// for (i = 0; i < 3; i = i + 1) begin
			//     $display("%d %d %d %d %d %d %d %d %d %d %d %d %d %d", 
			// 	     IFM_Buffer[i*14], IFM_Buffer[i*14 + 1], IFM_Buffer[i*14 + 2], 
			// 	     IFM_Buffer[i*14 + 3], IFM_Buffer[i*14 + 4], IFM_Buffer[i*14 + 5], 
			// 	     IFM_Buffer[i*14 + 6], IFM_Buffer[i*14 + 7], IFM_Buffer[i*14 + 8], 
			// 	     IFM_Buffer[i*14 + 9], IFM_Buffer[i*14 + 10], IFM_Buffer[i*14 + 11], 
			// 	     IFM_Buffer[i*14 + 12], IFM_Buffer[i*14 + 13]);
			// end
		end	
	end

end
///////////////////////////////////////////////////////

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        state_cs <= IDLE;		// reset state_cs to IDLE when rst_n clock = 0
    else
        state_cs <= state_ns;	// set state_cs to state_ns 
end

always@(*) begin				// this block active whenever inputs change
    case(state_cs)
        IDLE:					// if state_cs = IDLE
        begin
            if(in_valid && (count < 42))		// if in_valid and less than 42 input is loaded
                state_ns = IN_DATA;
            else if (in_valid && (count >= 42)) // if in_valid and 42 or more input is loaded
                state_ns = EXE;
            else
                state_ns = IDLE;
        end
        IN_DATA:				// if state_cs = IN_DATA
        begin
            if (count >= 42)	// if 42 or more input is loaded
                state_ns = EXE;
            else
                state_ns = IN_DATA;
        end
        EXE:					// if state_cs = EXE
        begin
            if(in_valid !== 1)		// if not in_valid
                state_ns = IDLE;
            else
                state_ns = EXE;
        end
        default:
        begin				// if state_cs != IDLE or IN_DATA or EXE
            state_ns = IDLE;
        end
    endcase
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count <= 0;
		current_IFM <=0;
		current_OFM_Buffer <= 0;
		first_convolution_done <= 0;
		last_convolution_done <= 0;
	end
end
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
	else if(state_cs == EXE) begin	
		$display("IFM_Buffer 3x3 Matrix:");
        $display("%d %d %d", IFM_Buffer[current_IFM], IFM_Buffer[current_IFM+1], IFM_Buffer[current_IFM+2]);
        $display("%d %d %d", IFM_Buffer[current_IFM+14], IFM_Buffer[current_IFM+15], IFM_Buffer[current_IFM+16]);
        $display("%d %d %d", IFM_Buffer[current_IFM+28], IFM_Buffer[current_IFM+29], IFM_Buffer[current_IFM+30]);

		$display("Weight_Buffer 3x3 Matrix:");
        $display("%d %d %d", Weight_Buffer[0], Weight_Buffer[1], Weight_Buffer[2]);
        $display("%d %d %d", Weight_Buffer[3], Weight_Buffer[4], Weight_Buffer[5]);
        $display("%d %d %d", Weight_Buffer[6], Weight_Buffer[7], Weight_Buffer[8]);

		OFM_Buffer[current_OFM_Buffer] <= IFM_Buffer[0]*Weight_Buffer[0]			// 3x3 convolution
				  +IFM_Buffer[1]*Weight_Buffer[1]
				  +IFM_Buffer[2]*Weight_Buffer[2]
				  +IFM_Buffer[14]*Weight_Buffer[3]
				  +IFM_Buffer[15]*Weight_Buffer[4]
				  +IFM_Buffer[16]*Weight_Buffer[5]
				  +IFM_Buffer[28]*Weight_Buffer[6]
				  +IFM_Buffer[29]*Weight_Buffer[7]
				  +IFM_Buffer[30]*Weight_Buffer[8];

		// OFM_Buffer[current_OFM_Buffer] <= IFM_Buffer[current_IFM]*Weight_Buffer[0]			// 3x3 convolution
		// 		  +IFM_Buffer[current_IFM+1]*Weight_Buffer[1]
		// 		  +IFM_Buffer[current_IFM+2]*Weight_Buffer[2]
		// 		  +IFM_Buffer[current_IFM+14]*Weight_Buffer[3]
		// 		  +IFM_Buffer[current_IFM+15]*Weight_Buffer[4]
		// 		  +IFM_Buffer[current_IFM+16]*Weight_Buffer[5]
		// 		  +IFM_Buffer[current_IFM+28]*Weight_Buffer[6]
		// 		  +IFM_Buffer[current_IFM+29]*Weight_Buffer[7]
		// 		  +IFM_Buffer[current_IFM+30]*Weight_Buffer[8];
		if(current_IFM < 12) begin
			current_IFM <= current_IFM + 1;
		end
		else begin
			current_IFM <= 0;
		end
		current_OFM_Buffer <= current_OFM_Buffer + 1;
		first_convolution_done <= 1;
		if(current_OFM_Buffer == 143) begin
			last_convolution_done <= 1;
		end
	end
	else begin
		for (i=0;i<143;i=i+1)
			OFM_Buffer[i] <= 0;
	end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Out_OFM <= 0;
    end
    else if(last_convolution_done == 1) begin
		Out_OFM[i] <= max_pooling(
                    OFM_Buffer[current_pooling],
                    OFM_Buffer[current_pooling + 1],
                    OFM_Buffer[current_pooling + 12],
                    OFM_Buffer[current_pooling + 13]);
		i = i + 1;
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
