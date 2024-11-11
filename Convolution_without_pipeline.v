module Convolution_without_pipeline(
	//input
clk,
rst_n,
in_valid,
In_IFM,
In_Weight,
//output
out_valid,
Out_OFM,
);

input clk, rst_n, in_valid; 
input [15:0]In_IFM;
input [15:0]In_Weight;

//////////////The output port shoud be registers///////////////////////
output reg out_valid;
output reg[35:0] Out_OFM;
//////////////////////////////////////////////////////////////////////


/////// 2 Buffer/////////////
//You have to sue these buffers for the 3-1 ///////
reg [15:0]IFM_Buffer[0:195] ;   //  Use this buffer to store IFM
reg [15:0]Weight_Buffer[0:8];  //  Use this buffer to store Weight
reg [35:0] OFM_Buffer [0:143]; // i fixed provide input from 25 to 144
reg [35:0] POOLING_Buffer [0:35];
/////////////////////////////////////


//==============================================//
//             Parameter and Integer            //
//==============================================//
//state parameter 
parameter IDLE = 3'd0, IN_DATA = 3'd1, CONV = 3'd2, OUT = 3'd3; //OUT is also the result of max pooling
//==============================================//
//             reg declaration                  //
//==============================================//
//stage register, corresponding with number parameter needed  
integer i;
reg [1:0] current_state, next_state;
reg [7:0] count, sliding_window_num, in_index, in_index_pool;
reg [5:0] window_pooling;
reg [35:0] Out_conv; 
wire [35:0] out_combine;
wire [35:0] out_final;
wire [31:0] mul0, mul1, mul2, mul3, mul4, mul5, mul6, mul7, mul8;
wire [32:0] add0_l1, add1_l1,  add2_l1, add3_l1;
wire [33:0] add0_l2, add1_l2;
wire [34:0] add0_l3; 
    

//need fix count 

always @(posedge clk, negedge rst_n) begin 
    if (!rst_n ) 
        count <= 0;
    else if (next_state == IDLE && !in_valid)
        count <= 0;
    else
        count <= count + 8'd1;
end 


//=====================================================//
//             Giving value for current state          //
//=====================================================//
always @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        current_state <= IDLE; 
    else 
        current_state <= next_state ;
end 

//=====================================================//
//             Giving value for next state : FSM       //
//=====================================================//

always @(*)
    case (current_state)
        IDLE: begin 
            if (in_valid)
                next_state <= IN_DATA;
            else 
                next_state <= IDLE;
        end 
        IN_DATA: begin 
            if (in_valid)
            //if (in_valid)
                next_state <= IN_DATA;
            else 
                next_state <= CONV;
        end 
        CONV: begin
            if (sliding_window_num == 'd143  )
                next_state <= OUT;
            else 
                next_state <= CONV; 
        end 
        OUT: begin
            if(window_pooling == 'd35) 
                next_state <= IDLE;
            else 
                next_state <= OUT; 
        end
        default: next_state <= IDLE ; 

    endcase 

//=====================================================//
//             Giving buffer for weight and IFM        //
//=====================================================//
////////Here just an example of how to use IFM_buffer & WEight_Buffer to store data////////
//The storage mechanism can be modified, but not the buffer size cannot be modified
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i=0;i<9;i=i+1)
			Weight_Buffer[i] <= 0;
	end
	else if(in_valid && count < 'd9)
		Weight_Buffer[count] <= In_Weight;
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i=0;i<196;i=i+1)
			IFM_Buffer[i] <= 0;
	end
	else if(count < 'd196) begin
		IFM_Buffer[count]  <= In_IFM;
	end

end

//need increase enable signal follow clock
//=====================================================//
//     IN_DATA state: setup input for convolution      //
//=====================================================//
always@(posedge clk or negedge rst_n) begin 
    if(!rst_n) 
        sliding_window_num <= 0; 
    else if (current_state == CONV)
        sliding_window_num <= sliding_window_num + 8'd1;
    else 
        sliding_window_num <= 0;
    end 

//determine which cell (index) should out from mux
always @(*) begin
    if (sliding_window_num < 12 ) begin
        in_index = sliding_window_num; 
    end 
    else if (sliding_window_num >=12  && sliding_window_num <24 ) begin
        in_index = sliding_window_num + 2; 
    end
    else if (sliding_window_num >=24  && sliding_window_num <36 ) begin 
        in_index = sliding_window_num + 4;
    end
    else if (sliding_window_num >=36 && sliding_window_num <48) begin 
        in_index = sliding_window_num + 6;
    end 
    else if (sliding_window_num >=48 && sliding_window_num <60) begin 
        in_index = sliding_window_num + 8;
    end
    else if (sliding_window_num >=60 && sliding_window_num <72) begin 
        in_index = sliding_window_num + 10;
    end
    else if (sliding_window_num >=72 && sliding_window_num <84) begin 
        in_index = sliding_window_num + 12;
    end
    else if (sliding_window_num >=84 && sliding_window_num <96) begin 
        in_index = sliding_window_num + 14;
    end
    else if (sliding_window_num >=96 && sliding_window_num <108) begin 
        in_index = sliding_window_num + 16; 
    end
    else if (sliding_window_num >=108 && sliding_window_num <120) begin 
        in_index = sliding_window_num + 18;
    end
    else if (sliding_window_num >=120 && sliding_window_num <132) begin
        in_index = sliding_window_num + 20;
    end 
    else  begin 
        in_index = sliding_window_num + 22;
    end
    
end  
    

//=====================================================//
//             CONV state                              //
//=====================================================//

 always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
    begin
		Out_conv <= 0;
    end
       // so with each clk, we will get the o/p mux follow the order, if sliding window = 0, o/p conv will represent as below, if sliding window = 1, we will have index = 1,2,3;15,16,17;29,30,31
	else if(current_state  == CONV) begin
		Out_conv <= out_combine;
    end
	else
    begin
		Out_conv <= 0;
    end   
 end 
   
    assign mul0 = IFM_Buffer[in_index] * Weight_Buffer[0] ;
    assign mul1 = IFM_Buffer[in_index + 1] * Weight_Buffer[1] ;
    assign mul2 = IFM_Buffer[in_index + 2] * Weight_Buffer[2] ;

    assign mul3 = IFM_Buffer[in_index + 14] * Weight_Buffer[3] ;
    assign mul4 = IFM_Buffer[in_index + 15] * Weight_Buffer[4] ;
    assign mul5 = IFM_Buffer[in_index + 16] * Weight_Buffer[5] ;

    assign mul6 = IFM_Buffer[in_index + 28] * Weight_Buffer[6] ;
    assign mul7 = IFM_Buffer[in_index + 29] * Weight_Buffer[7] ;
    assign mul8 = IFM_Buffer[in_index + 30] * Weight_Buffer[8] ;

    assign add0_l1 = mul1 + mul2; 
    assign add1_l1 = mul3 + mul4;
    assign add2_l1 = mul5 + mul6; 
    assign add3_l1 = mul7 + mul8; 

    assign add0_l2 = add0_l1 + add1_l1; 
    assign add1_l2 = add2_l1 + add3_l1;

    assign add0_l3 = add0_l2 + add1_l2; 
    assign out_combine = add0_l3 + mul0;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i=0;i< 144;i=i+1)
			OFM_Buffer[i] <= 0;
	end
	else if( sliding_window_num <= 144) begin
		OFM_Buffer[sliding_window_num - 1]  <= Out_conv;
	end

end
//=====================================================//
//             POOLING                                 //
//=====================================================//
always@(posedge clk or negedge rst_n) begin 
    if(!rst_n) 
        window_pooling <= 0; 
    else if (current_state == OUT)
        window_pooling <= window_pooling + 8'd1;
    else 
        window_pooling <= 0;
    end 

always @(*) begin
    if (window_pooling < 'd6 ) begin
        in_index_pool = window_pooling * 2; 
    end 
    else if (window_pooling >='d6  && window_pooling <'d12 ) begin
        in_index_pool = window_pooling*2 + 12; 
    end
    else if (window_pooling >='d12  && window_pooling <'d18 ) begin
        in_index_pool = window_pooling*2 + 24; 
    end
    else if (window_pooling >='d18  && window_pooling <'d24 ) begin
        in_index_pool = window_pooling*2 + 36; 
    end
    else if (window_pooling >='d24  && window_pooling <'d30 ) begin
        in_index_pool = window_pooling*2 + 48; 
    end
    else if (window_pooling >='d30  && window_pooling <'d36 ) begin
        in_index_pool = window_pooling*2 + 60; 
    end
    else 
        in_index_pool = window_pooling * 2;
end
comp_4in comp(.in0(OFM_Buffer[in_index_pool]), .in1(OFM_Buffer[in_index_pool + 1]), .in2(OFM_Buffer[in_index_pool + 12]), .in3(OFM_Buffer[in_index_pool + 13]), .out_max(out_final) ); 

always@(posedge clk or negedge rst_n) begin
	if(!rst_n )    begin
		Out_OFM <= 0;
    end
    else if (count == 228) begin
        Out_OFM <= 0;
    end 
    else if(current_state  == OUT) begin
		Out_OFM <= out_final;
    end
	else
    begin
		Out_OFM <= 0;
    end   
 end 

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i=0;i<36;i=i+1)
			POOLING_Buffer[i] <= 0;
	end
	else if(window_pooling < 36) begin
		POOLING_Buffer[window_pooling]  <= Out_OFM;
	end

end
//reset output


//set up output valid 
always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out_valid <= 0;
    else if (current_state == OUT)
        out_valid <= 2'b1; 
    else 
        out_valid <= 0; 
end 
endmodule 

module comp_4in (in0, in1, in2, in3, out_max);

    input [35 : 0] in0, in1, in2, in3;
    output [35 : 0] out_max; //compare between mid_a and mid_b
 

    //interconnection
    wire [35 : 0] mid_a;  //compare between in0, in1
    wire [35 : 0] mid_b; //compare between in2, in3
    //body 
    assign mid_a = (in0 > in1) ? in0 : in1; 
    assign mid_b = (in2 > in3) ? in2 : in3; 
    assign out_max = (mid_a > mid_b) ? mid_a : mid_b; 

endmodule 
/*

comp_4in comp1 (OFM_Buffer[0],OFM_Buffer[1],OFM_Buffer[12], OFM_Buffer[13], out_max[0]) ;
comp_4in comp2 (OFM_Buffer[2],OFM_Buffer[3],OFM_Buffer[14], OFM_Buffer[15], out_max[1]);
comp_4in comp3 (OFM_Buffer[4],OFM_Buffer[5],OFM_Buffer[16], OFM_Buffer[17], out_max[2]) ;

comp_4in comp4 (OFM_Buffer[6],OFM_Buffer[7],OFM_Buffer[18], OFM_Buffer[19], out_max[3]) ;
comp_4in comp5 (OFM_Buffer[8],OFM_Buffer[9],OFM_Buffer[20], OFM_Buffer[21], out_max[4]) ;
comp_4in comp6 (OFM_Buffer[10],OFM_Buffer[11],OFM_Buffer[22], OFM_Buffer[23], out_max[5]) ;
comp_4in comp7 (OFM_Buffer[24],OFM_Buffer[25],OFM_Buffer[36], OFM_Buffer[37], out_max[6]) ;
comp_4in comp8 (OFM_Buffer[26],OFM_Buffer[27],OFM_Buffer[38], OFM_Buffer[39], out_max[7]) ;
comp_4in comp9 (OFM_Buffer[28],OFM_Buffer[29],OFM_Buffer[40], OFM_Buffer[41], out_max[8]) ;
comp_4in comp10 (OFM_Buffer[30],OFM_Buffer[31],OFM_Buffer[42], OFM_Buffer[43], out_max[9]) ;
comp_4in comp11 (OFM_Buffer[32],OFM_Buffer[33],OFM_Buffer[44], OFM_Buffer[45], out_max[10]) ;
comp_4in comp12 (OFM_Buffer[34],OFM_Buffer[35],OFM_Buffer[46], OFM_Buffer[47], out_max[11]) ;

comp_4in comp13 (OFM_Buffer[48],OFM_Buffer[49],OFM_Buffer[60], OFM_Buffer[61], out_max[12]) ;
comp_4in comp14 (OFM_Buffer[50],OFM_Buffer[51],OFM_Buffer[62], OFM_Buffer[63], out_max[13]) ;
comp_4in comp15 (OFM_Buffer[52],OFM_Buffer[53],OFM_Buffer[64], OFM_Buffer[65], out_max[13]) ;

///////////////////////////////////////////////////////




endmodule



*/
/*
//MUX 49 to 9 implement 
always @(*)
    case (mux_ena) 
        6'd0 : out_mux = {IFM_Buffer[0],IFM_Buffer[1], IFM_Buffer[2], IFM_Buffer[7], IFM_Buffer[8], IFM_Buffer[9],IFM_Buffer[14], IFM_Buffer[15], IFM_Buffer[16] } ;   
        6'd1 : out_mux = {IFM_Buffer[1],IFM_Buffer[2], IFM_Buffer[3], IFM_Buffer[8], IFM_Buffer[9], IFM_Buffer[10],IFM_Buffer[15], IFM_Buffer[16], IFM_Buffer[17] } ; 
        6'd2 : out_mux = {IFM_Buffer[2],IFM_Buffer[3], IFM_Buffer[4], IFM_Buffer[9], IFM_Buffer[10], IFM_Buffer[11],IFM_Buffer[16], IFM_Buffer[17], IFM_Buffer[18] } ;   
        6'd3 : out_mux = {IFM_Buffer[3],IFM_Buffer[4], IFM_Buffer[5], IFM_Buffer[10], IFM_Buffer[11], IFM_Buffer[12],IFM_Buffer[17], IFM_Buffer[18], IFM_Buffer[19] } ;
        6'd4 : out_mux = {IFM_Buffer[4],IFM_Buffer[5], IFM_Buffer[6], IFM_Buffer[11], IFM_Buffer[12], IFM_Buffer[13],IFM_Buffer[18], IFM_Buffer[19], IFM_Buffer[20] } ;

        6'd5 : out_mux = {IFM_Buffer[7],IFM_Buffer[8], IFM_Buffer[9], IFM_Buffer[14], IFM_Buffer[15], IFM_Buffer[16],IFM_Buffer[21], IFM_Buffer[22], IFM_Buffer[23] } ; 
        6'd6 : out_mux = {IFM_Buffer[8],IFM_Buffer[9], IFM_Buffer[10], IFM_Buffer[15], IFM_Buffer[16], IFM_Buffer[17],IFM_Buffer[22], IFM_Buffer[23], IFM_Buffer[24] } ;   
        6'd7 : out_mux = {IFM_Buffer[9],IFM_Buffer[10], IFM_Buffer[11], IFM_Buffer[16], IFM_Buffer[17], IFM_Buffer[18],IFM_Buffer[23], IFM_Buffer[24], IFM_Buffer[25] } ;  
        6'd8 : out_mux = {IFM_Buffer[10],IFM_Buffer[11], IFM_Buffer[12], IFM_Buffer[17], IFM_Buffer[18], IFM_Buffer[19],IFM_Buffer[24], IFM_Buffer[25], IFM_Buffer[26] } ;   
        6'd9 : out_mux = {IFM_Buffer[11],IFM_Buffer[12], IFM_Buffer[13], IFM_Buffer[18], IFM_Buffer[19], IFM_Buffer[20],IFM_Buffer[25], IFM_Buffer[26], IFM_Buffer[27] } ; 

        6'd10 : out_mux = {IFM_Buffer[14],IFM_Buffer[15], IFM_Buffer[16], IFM_Buffer[21], IFM_Buffer[22], IFM_Buffer[23],IFM_Buffer[28], IFM_Buffer[29], IFM_Buffer[30] } ;  
        6'd11 : out_mux = {IFM_Buffer[15],IFM_Buffer[16], IFM_Buffer[17], IFM_Buffer[22], IFM_Buffer[23], IFM_Buffer[24],IFM_Buffer[29], IFM_Buffer[30], IFM_Buffer[31] } ; 
        6'd12 : out_mux = {IFM_Buffer[16],IFM_Buffer[17], IFM_Buffer[18], IFM_Buffer[23], IFM_Buffer[24], IFM_Buffer[25],IFM_Buffer[30], IFM_Buffer[31], IFM_Buffer[32] } ;  
        6'd13 : out_mux = {IFM_Buffer[17],IFM_Buffer[18], IFM_Buffer[19], IFM_Buffer[24], IFM_Buffer[25], IFM_Buffer[26],IFM_Buffer[31], IFM_Buffer[32], IFM_Buffer[33] } ;
        6'd14 : out_mux = {IFM_Buffer[18],IFM_Buffer[19], IFM_Buffer[20], IFM_Buffer[16], IFM_Buffer[17], IFM_Buffer[18],IFM_Buffer[23], IFM_Buffer[25], IFM_Buffer[25] } ;     

        6'd15 : out_mux = {IFM_Buffer[21],IFM_Buffer[22], IFM_Buffer[23], IFM_Buffer[28], IFM_Buffer[29], IFM_Buffer[30],IFM_Buffer[35], IFM_Buffer[36], IFM_Buffer[37] } ;
        6'd16 : out_mux = {IFM_Buffer[22],IFM_Buffer[23], IFM_Buffer[24], IFM_Buffer[29], IFM_Buffer[30], IFM_Buffer[31],IFM_Buffer[36], IFM_Buffer[37], IFM_Buffer[38] } ;   
        6'd17 : out_mux = {IFM_Buffer[23],IFM_Buffer[24], IFM_Buffer[25], IFM_Buffer[30], IFM_Buffer[31], IFM_Buffer[32],IFM_Buffer[37], IFM_Buffer[38], IFM_Buffer[39] } ;
        6'd18 : out_mux = {IFM_Buffer[24],IFM_Buffer[25], IFM_Buffer[26], IFM_Buffer[31], IFM_Buffer[32], IFM_Buffer[33],IFM_Buffer[38], IFM_Buffer[39], IFM_Buffer[40] } ;  
        6'd19 : out_mux = {IFM_Buffer[25],IFM_Buffer[26], IFM_Buffer[27], IFM_Buffer[32], IFM_Buffer[33], IFM_Buffer[34],IFM_Buffer[39], IFM_Buffer[40], IFM_Buffer[41] } ; 

        6'd20 : out_mux = {IFM_Buffer[28], IFM_Buffer[29], IFM_Buffer[30], IFM_Buffer[35], IFM_Buffer[36], IFM_Buffer[37],IFM_Buffer[42], IFM_Buffer[43], IFM_Buffer[44] } ; 
        6'd21 : out_mux = {IFM_Buffer[29], IFM_Buffer[30], IFM_Buffer[31], IFM_Buffer[36], IFM_Buffer[37], IFM_Buffer[38],IFM_Buffer[43], IFM_Buffer[44], IFM_Buffer[45] } ; 
        6'd22 : out_mux = {IFM_Buffer[30], IFM_Buffer[31], IFM_Buffer[32], IFM_Buffer[37], IFM_Buffer[38], IFM_Buffer[39],IFM_Buffer[44], IFM_Buffer[45], IFM_Buffer[46] } ; 
        6'd23 : out_mux = {IFM_Buffer[31], IFM_Buffer[32], IFM_Buffer[33], IFM_Buffer[38], IFM_Buffer[39], IFM_Buffer[40],IFM_Buffer[45], IFM_Buffer[46], IFM_Buffer[47] } ; 
        6'd24 : out_mux = {IFM_Buffer[33], IFM_Buffer[34], IFM_Buffer[35], IFM_Buffer[39], IFM_Buffer[40], IFM_Buffer[41],IFM_Buffer[46], IFM_Buffer[47], IFM_Buffer[48] } ; 
        default ..
   endcase 
//need increase enable signal follow clock
*/














