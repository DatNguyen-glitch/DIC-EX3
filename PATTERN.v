`timescale 1ns/1ps

`ifdef RTL
    `define CYCLE_TIME 0.75
`endif
`ifdef GATE
    `define CYCLE_TIME 0.75
`endif

/////////////////////////////////////////////////////////////////////////
// Project Name: Convolution						   				   //
// Task Name   : Convolution								  		   //
// Module Name : Convolution                               	  		   //
// File Name   : PATTERN.v                	  		   //
// Description : Convolution_without_pipeline			               //
// Author      : Yeh Shun Liang(EECS LAB)	 		                   //
// Revision History:                                                   //
/////////////////////////////////////////////////////////////////////////

module PATTERN(
    // Output signals
    clk,
	  in_valid,
	  rst_n,

    In_IFM,
	  In_Weight,

    // Input signals
	  out_valid,
	  Out_OFM
);

// ========================================
// I/O declaration
// ========================================
// Output
parameter IN_WIDTH  = 16;
parameter OUT_WIDTH = 36;

output reg       clk, rst_n;
output reg       in_valid;

output reg [IN_WIDTH-1:0] In_IFM;
output reg [IN_WIDTH-1:0] In_Weight;

// Input
input out_valid;
input[OUT_WIDTH-1:0] Out_OFM;
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
integer total_latency, latency;
integer out_val_clk_times;
integer i_pat,i,j;
integer input_matrix_size;
integer idx_count;
integer golden_size;
integer index_op;
integer flag;


// ========================================
// wire & reg
// ========================================
reg [IN_WIDTH-1:0] input_img_buf[0:13][0:13];
reg [IN_WIDTH-1:0] input_template_buf[0:2][0:2];

//================================================================
// initial
//================================================================
initial begin
  pat_read = $fopen("../00_TESTBED/input.txt", "r");
  ans_read = $fopen("../00_TESTBED/output.txt", "r");
  reset_signal_task;

  i_pat = 0;
  total_latency = 0;
  idx_count = 0;
  file = $fscanf(pat_read, "%d\n", PAT_NUM);

  for (i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat + 1)
  begin
    latency = -1;

    index_op=0;
    flag=0;
    input_task_1;
	  wait_out_valid_task;
    check_ans_task;

    total_latency = total_latency + latency;
    $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %4d,\033[m",i_pat , latency);
  end
  $fclose(pat_read);

  YOU_PASS_task;
end

initial begin
  while(1) begin
    if((out_valid === 0) && (out_valid !== 0))
    begin
      $display("***********************************************************************");
      $display("*  Error                                                              *");
      $display("*  The out_data should be reset when out_valid is low.                *");
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end
    // if((in_valid === 1) && (out_valid === 1))
    // begin
    //   $display("***********************************************************************");
    //   $display("*  Error                                                              *");
    //   $display("*  The out_valid cannot overlap with in_valid.                        *");
    //   $display("***********************************************************************");
    //   repeat(2)@(negedge clk);
    //   $finish;
    // end
    @(negedge clk);
  end
end

//================================================================
// task
//================================================================
task reset_signal_task;
begin
  rst_n    = 1;
  in_valid = 1'b0;
  flag=0;
  index_op=0;

  force clk= 0;
  #(0.5 * CYCLE);
  rst_n = 0;

  In_IFM = 16'bx;
  In_Weight = 16'bx;

  for (i=0; i<36; i=i+1) Out_OFM_temp[i] = 0;

  #(10 * CYCLE);
  if( (out_valid !== 0) || (Out_OFM !== 0) )
  begin
    $display("***********************************************************************");
    $display("*  Error                                                              *");
    $display("*  Output signal should reset after initial RESET                     *");
    $display("***********************************************************************");
    $finish;
  end
  #(CYCLE);  rst_n=1;
  #(CYCLE);  release clk;
end
endtask

integer kernal_cnt;
integer image_shape_w;

task input_task_1;
begin
  image_shape_w = 14;

  // buffered the rgb img
  for(i = 0; i<image_shape_w ; i=i+1)
  	for(j = 0; j < image_shape_w; j=j+1)
        	file = $fscanf(pat_read, "%d", input_img_buf[i][j]);

  // buffer the template
  for(i = 0; i < 3; i=i+1)
  	for(j = 0; j < 3; j=j+1)
        file  = $fscanf(pat_read, "%d", input_template_buf[i][j]);

  // Set pattern signal
  repeat(3)@(negedge clk);

  in_valid = 1'b1;
  kernal_cnt = 0;


  // Sends matrix
  for(i = 0; i < image_shape_w; i=i+1)
    for(j = 0; j < image_shape_w; j=j+1)
    	begin
        if (flag==1 && out_valid == 0)  begin
          $display("***********************************************************************");
          $display("*  Error                                                              *");
          $display("*  out_valid should be continuous.                                    *");
          $display("***********************************************************************");
          repeat(2)@(negedge clk);
          $finish;
        end
        if (out_valid) begin
          flag=1;
          Out_OFM_temp[index_op] = Out_OFM;

          // $display("Store Out_OFM = %30d", Out_OFM);
          // $display("fuck");
          // $display("Store Out_OFM_temp[%d] = %30d", index_op, Out_OFM_temp[index_op]);
          index_op=index_op+1;
        end
    	  In_IFM = input_img_buf[i][j];

        if(kernal_cnt < 9)
        begin
            In_Weight = input_template_buf[kernal_cnt/3][kernal_cnt%3];
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
  In_IFM   = 'bx;
  latency = 144;

end
endtask

task wait_out_valid_task;
begin
  while(out_valid !== 1)
  begin
    latency = latency + 1;
    if(latency >= 5000)
    begin
      $display("***********************************************************************");
      $display("*  Error                                                              *");
      $display("*  The execution latency are over  5000 cycles.                      *");
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end
    @(negedge clk);
  end
end
endtask

reg[OUT_WIDTH-1:0] golden_word;

task check_ans_task;
begin
  // OUTPUT IS 6X6
  golden_size = 6;
  // $display("golden_size*golden_size-index_op = %30d", golden_size*golden_size-index_op);
  for (i=index_op; i<golden_size*golden_size; i=i+1) begin
    if (flag==1 && out_valid == 0)  begin
      $display("***********************************************************************");
      $display("*  Error                                                              *");
      $display("*  out_valid should be continuous.                                    *");
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end
    if (out_valid) begin
      flag=1;
      Out_OFM_temp[i] = Out_OFM;

      // $display("Store Out_OFM = %30d", Out_OFM);
      // $display("fuck");
      // $display("Store Out_OFM_temp[%d] = %30d", i, Out_OFM_temp[i]);
      index_op=index_op+1;
    end
    @(negedge clk);
  end
  flag=0;


  for(i=0; i<golden_size ; i=i+1)
      for(j=0 ; j < golden_size; j=j+1)
      begin
        file = $fscanf(ans_read,"%d ",golden_word);
        latency = latency + 1;
        // if(out_valid !== 1)
        // begin
        //   $display("***********************************************************************");
        //   $display("*  Error                                                              *");
        //   $display("*  Out valid should be 1 when outputing the data                      *");
        //   $display("*  Current index of output matrix %d , bit of output matrix %d *",i,j   );
        //   $display("***********************************************************************");
        //   repeat(2)@(negedge clk);
        //   $finish;
        // end

        if(Out_OFM_temp[i*6+j] !== golden_word)
        begin
           $display("***********************************************************************");
           $display("*  Error                                                              *");
           $display("*  The out_data should be correct when out_valid is high              *");
           $display("*  Your output : %d                                           *",Out_OFM_temp[i*6+j]);
           $display("*  Golden       : 0b%30b                    *",golden_word);
           $display("*  Golden       : %30d                      *",golden_word);
           $display("*  Golden       : 0b%30b                    *",golden_word);
           $display("***********************************************************************");
           repeat(2)@(negedge clk);
           $finish;
        end
        // @(negedge clk);
      end


  if(out_valid !== 0  || Out_OFM !== 0)
      begin
          $display("***********************************************************************");
          $display("*  Error                                                              *");
          $display("*  Output signal should reset after outputting the data               *");
          $display("***********************************************************************");
          repeat(2)@(negedge clk);
          $finish;
  end
  total_latency = total_latency + latency;
  for (i=0; i<36; i=i+1) Out_OFM_temp[i] = 0;
  flag=0;
  index_op=0;

  repeat(4)@(negedge clk);
end
endtask


task YOU_PASS_task; begin
  $display("***********************************************************************");
  $display("*                           \033[0;32mCongratulations!\033[m                          *");
  $display("*  Your execution cycles = %18d   cycles                *", total_latency);
  $display("*  Your clock period     = %20.1f ns                    *", CYCLE);
  $display("*  Total Latency         = %20.1f ns                    *", total_latency*CYCLE);
  $display("***********************************************************************");
  $finish;
end endtask


endmodule