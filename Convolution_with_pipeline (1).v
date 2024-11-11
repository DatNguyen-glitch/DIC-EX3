module Convolution_with_pipeline(
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
output reg[35:0] Out_OFM ;
//////////////////////////////////////////////////////////////////////


/////// 2 Buffer/////////////
//You have to sue these buffers for the 3-1 ///////
reg [15:0]IFM_Buffer[0:195] ;   //  Use this buffer to store IFM
reg [15:0]Weight_Buffer[0:8];  //  Use this buffer to store Weight
reg [35:0] OFM_Buffer [0:143]; // i fixed provide input from 25 to 144
reg [35:0] POOLING_Buffer [0:35];
reg [35:0] Out_OFM_1;
/////////////////////////////////////


//==============================================//
//             Parameter and Integer            //
//==============================================//
//state parameter 
parameter IDLE = 2'd0, IN_DATA = 2'd1, CONV = 2'd2, OUT = 2'd3; //OUT is also the result of max pooling
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
wire [31:0] mul0_ns, mul1_ns, mul2_ns, mul3_ns, mul4_ns, mul5_ns, mul6_ns, mul7_ns, mul8_ns;
wire [32:0] add0_l1_ns, add1_l1_ns,  add2_l1_ns, add3_l1_ns;
wire [33:0] add0_l2_ns, add1_l2_ns;
wire [34:0] add0_l3; 
    

//need fix count 

always @(posedge clk, negedge rst_n) begin 
    if (!rst_n ) 
        count <= 0;
    else if (current_state == IDLE && !in_valid)
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
            if (count > 'd56)
            //if (in_valid)
                next_state <= CONV;
            else 
                next_state <= IN_DATA;
        end 
        CONV: begin
            if (sliding_window_num == 'd148 )
                next_state <= OUT;
            else 
                next_state <= CONV; 
        end 
        OUT: begin
            if(window_pooling == 'd36) 
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
    reg [31:0] mul0, mul1, mul2, mul3, mul4, mul5, mul6, mul7, mul8;
    reg [15:0] IFM_cal[0:8];
    always @(posedge clk) begin 
        IFM_cal[0] <= IFM_Buffer[in_index];
        IFM_cal[1] <= IFM_Buffer[in_index + 1];
        IFM_cal[2] <= IFM_Buffer[in_index + 2];
        IFM_cal[3] <= IFM_Buffer[in_index + 14];
        IFM_cal[4] <= IFM_Buffer[in_index + 15];
        IFM_cal[5] <= IFM_Buffer[in_index + 16];
        IFM_cal[6] <= IFM_Buffer[in_index + 28];
        IFM_cal[7] <= IFM_Buffer[in_index + 29];
        IFM_cal[8] <= IFM_Buffer[in_index + 30];
    end 
    /*assign mul0_ns = IFM_Buffer[in_index] * Weight_Buffer[0] ;
    assign mul1_ns = IFM_Buffer[in_index + 1] * Weight_Buffer[1] ;
    assign mul2_ns = IFM_Buffer[in_index + 2] * Weight_Buffer[2] ;

    assign mul3_ns = IFM_Buffer[in_index + 14] * Weight_Buffer[3] ;
    assign mul4_ns = IFM_Buffer[in_index + 15] * Weight_Buffer[4] ;
    assign mul5_ns = IFM_Buffer[in_index + 16] * Weight_Buffer[5] ;

    assign mul6_ns = IFM_Buffer[in_index + 28] * Weight_Buffer[6] ;
    assign mul7_ns = IFM_Buffer[in_index + 29] * Weight_Buffer[7] ;
    assign mul8_ns = IFM_Buffer[in_index + 30] * Weight_Buffer[8] ; */
    assign mul0_ns = IFM_cal[0] * Weight_Buffer[0] ;
    assign mul1_ns = IFM_cal[1] * Weight_Buffer[1] ;
    assign mul2_ns = IFM_cal[2] * Weight_Buffer[2] ;

    assign mul3_ns = IFM_cal[3] * Weight_Buffer[3] ;
    assign mul4_ns = IFM_cal[4] * Weight_Buffer[4] ;
    assign mul5_ns = IFM_cal[5] * Weight_Buffer[5] ;

    assign mul6_ns = IFM_cal[6] * Weight_Buffer[6] ;
    assign mul7_ns = IFM_cal[7] * Weight_Buffer[7] ;
    assign mul8_ns = IFM_cal[8] * Weight_Buffer[8] ;

	always @(posedge clk) begin 
		mul0 <= mul0_ns;
		mul1 <= mul1_ns;
		mul2 <= mul2_ns;
		mul3 <= mul3_ns;
		mul4 <= mul4_ns;
		mul5 <= mul5_ns;
		mul6 <= mul6_ns;
		mul7 <= mul7_ns;
		mul8 <= mul8_ns;
	end 

	assign add0_l1_ns = mul1 + mul2; 
    assign add1_l1_ns = mul3 + mul4;
    assign add2_l1_ns = mul5 + mul6; 
    assign add3_l1_ns = mul7 + mul8; 

    reg[32:0] add0_l1, add1_l1, add2_l1, add3_l1, add4_l1 ;
    always @(posedge clk) begin 
        add0_l1 <= add0_l1_ns;
        add1_l1 <= add1_l1_ns;
        add2_l1 <= add2_l1_ns;
        add3_l1 <= add3_l1_ns; 
        add4_l1 <= mul0;
    end 
	reg [33:0] add0_l2, add1_l2, add2_l2; 
    assign add0_l2_ns = add0_l1 + add1_l1; 
    assign add1_l2_ns = add2_l1 + add3_l1;
	always @(posedge clk) begin 
		add0_l2 <= add0_l2_ns; 
		add1_l2 <= add1_l2_ns; 
		add2_l2 <= add4_l1; 
	end 

    assign add0_l3 = add0_l2 + add1_l2; 
    assign out_combine = add0_l3 + add2_l2;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i=0;i< 144;i=i+1)
			OFM_Buffer[i] <= 0;
	end
	else if( sliding_window_num <=148) begin
		OFM_Buffer[sliding_window_num - 5]  <= Out_conv;
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
comp_4in comp(.clk(clk),.in0(OFM_Buffer[in_index_pool]), .in1(OFM_Buffer[in_index_pool + 1]), .in2(OFM_Buffer[in_index_pool + 12]), .in3(OFM_Buffer[in_index_pool + 13]), .out_max(out_final) ); 

always@(posedge clk or negedge rst_n) begin
	if(!rst_n )    begin
		Out_OFM_1 <= 0;
    end
    else if (count == 248) begin
        Out_OFM_1 <= 0;
    end 
    else if(current_state  == OUT) begin
		Out_OFM_1 <= out_final;
    end
	else
    begin
		Out_OFM_1 <= 0;
    end   
 end 

/*always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for (i=0;i<36;i=i+1)
			POOLING_Buffer[i] <= 0;
	end
	else if(window_pooling < 36) begin
		POOLING_Buffer[window_pooling-2]  <= Out_OFM_1;
	end 
end */
always @(*) begin 
    if (window_pooling >= 2)
        Out_OFM = Out_OFM_1; 
    else 
        Out_OFM = 0;
end 


//set up output valid 
always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out_valid <= 0;
    else if (current_state == OUT && count > 'd207)
        out_valid <= 2'b1; 
    else 
        out_valid <= 0; 
end 
endmodule 

module comp_4in (clk,in0, in1, in2, in3, out_max);

    input clk;
    input [35 : 0] in0, in1, in2, in3;
    output [35 : 0] out_max; //compare between mid_a and mid_b
 

    //interconnection
    wire [35 : 0] mid_a_ns;  //compare between in0, in1
    wire [35 : 0] mid_b_ns; //compare between in2, in3
    reg [35:0] mid_a, mid_b;
    //body 
    assign mid_a_ns = (in0 > in1) ? in0 : in1; 
    assign mid_b_ns = (in2 > in3) ? in2 : in3; 

    always @(posedge clk) begin 
        mid_a <= mid_a_ns;
        mid_b <= mid_b_ns; 
    end 
    assign out_max = (mid_a > mid_b) ? mid_a : mid_b; 

endmodule 














