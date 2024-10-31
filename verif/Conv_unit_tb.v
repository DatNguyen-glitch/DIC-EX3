
`timescale 1ns/1ps

`ifdef RTL
    `define CYCLE_TIME 0.75
`endif
`ifdef GATE
    `define CYCLE_TIME 0.75
`endif


`ifdef RTL
  `include "../verif/Convolution_without_pipeline.v"
`endif

`ifdef GATE
  `include "../02_SYN/Netlist/Convolution_without_pipeline_SYN.v"
`endif


module Conv_unit_tb;
	reg clk;
	reg rst_n;
	reg in_valid;
	wire weight_valid;
	reg [15:0]In_IFM;
	reg [15:0]In_Weight;

	wire out_valid;
	wire [35:0] Out_OFM;
	wire [35:0] conv_out;


parameter IN_WIDTH  = 16;
parameter OUT_WIDTH = 36;

reg [OUT_WIDTH-1:0] Out_OFM_temp[35:0];

// ========================================
// clock
// ========================================
real CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk; //clock


// ========================================
// integer & parameter
// ========================================
integer pat_read, ans_read, file;
integer PAT_NUM;
integer i_pat,i,j;
integer kernal_cnt;
integer fd;
integer cnt_out;

// ========================================
// wire & reg
// ========================================
reg [IN_WIDTH-1:0] input_dat_buf[0:195];
reg [IN_WIDTH-1:0] input_wei_buf[0:9];
reg [35:0] buf_conv_out [0:143];

initial begin
  `ifdef RTL
    $fsdbDumpfile("Conv_unit_tb.fsdb");
    $fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();
  `endif
  `ifdef GATE
    $sdf_annotate("../02_SYN/Netlist/Convolution_without_pipeline_SYN.sdf",u_Convolution_without_pipeline);
    $fsdbDumpfile("Convolution_without_pipeline_SYN.fsdb");
    $fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();
  `endif
end


`ifdef RTL
Convolution_without_pipeline	u_Convolution_without_pipeline	(
		.clk(clk),
		.rst_n(rst_n),
		.in_valid(in_valid),
		.In_IFM(In_IFM),
		.In_Weight(In_Weight),
		.reg_conv_out(conv_out),
		.out_valid(out_valid),
		.Out_OFM(Out_OFM)
		);
`endif

`ifdef GATE
Convolution_without_pipeline	u_Convolution_without_pipeline	(
		.clk(clk),
		.rst_n(rst_n),
		.in_valid(in_valid),
		.In_IFM(In_IFM),
		.In_Weight(In_Weight),
		.reg_conv_out(conv_out),
		.out_valid(out_valid),
		.Out_OFM(Out_OFM)
		);
`endif

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cnt_out <= 0; 
		for ( i = 0; i < 144; i = i+1) begin
			buf_conv_out [i] <= 0;
		end
	end
	else begin
		if ( out_valid ) begin
			buf_conv_out [cnt_out] <= conv_out;
			cnt_out <= cnt_out + 1;
		end
		else begin
			cnt_out <= cnt_out;
		end
	end

end


initial begin
	pat_read = $fopen("../verif/input.txt", "r");
//	ans_read = $fopen("../verif/output.txt", "r");
	task_reset_signal;
	
	i_pat = 0;
	file = $fscanf(pat_read, "%d\n", PAT_NUM);
	
	for (i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat + 1)
	begin
		task_feed_input;
		#40
		task_check_ans;
	end
	$fclose(pat_read);
	#40 $finish;
end


task task_check_ans;
	begin
		fd = $fopen("data_out.log", "w");
			for (i = 0; i < 144; i = i +1) begin
				$fdisplay(fd, " %d", buf_conv_out[i]);
			end
		$fclose(fd);
	end
endtask


task task_reset_signal;
begin
  rst_n    = 1;
  in_valid = 1'b0;

  force clk= 0;
  #(0.5 * CYCLE);
  rst_n = 0;

  In_IFM = 16'bx;
  In_Weight = 16'bx;

  for (i=0; i<36; i=i+1) Out_OFM_temp[i] = 0;

  #(10 * CYCLE);
  #(CYCLE);  rst_n=1;
  #(CYCLE);  release clk;
end
endtask

task task_feed_input;
begin
	fd = $fopen("data_in.log", "w");
		$fdisplay(fd, "");
	$fclose(fd);

	for(i = 0; i < 196 ; i = i+1)
        file = $fscanf(pat_read, "%d", input_dat_buf[i]);

	for(i = 0; i < 9; i = i+1)
        file  = $fscanf(pat_read, "%d", input_wei_buf[i]);

//  repeat(3)@(negedge clk);

	in_valid = 1'b1;
	kernal_cnt = 0;

	for(i = 0; i < 196; i = i+1) begin
		In_IFM = input_dat_buf[i];
		fd = $fopen("data_in.log", "a");
			$fdisplay(fd, "data: %d", In_IFM);
	 	$fclose(fd);	
		if(kernal_cnt < 9)	begin
		    In_Weight = input_wei_buf[i];
			fd = $fopen("data_in.log", "a");
				$fdisplay(fd, "weight: %d", In_Weight);
			 $fclose(fd);
		end
		else
		begin
			In_Weight = 16'bx;
        end

        kernal_cnt = kernal_cnt + 1;
		@(negedge clk);
    	end

	// Clear in_valid and matrix
	in_valid = 1'b0;
	In_IFM   = 16'bx;
end
endtask

endmodule
