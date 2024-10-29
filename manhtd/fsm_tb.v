
`include "../verilog/fsm.v"

module fsm_tb;

    // Inputs
    reg clk;
    reg reset;
	reg [5:0] count1;
	reg [3:0] count2;
	reg [1:0] count3;
		
    // Outputs
    wire [1:0] state;

    parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10;
 
	// Instantiate the FSM
    fsm uut (
        .clk(clk),
        .reset(reset),
		.count_data(count1), 
		.count_line(count2), 
		.count_wind(count3), 
        .state(state)
    );

	always @(posedge clk or negedge reset) begin
		if (reset)	begin
			count1 <= 6'b000000;
			count2 <= 4'b0000;
			count3 <= 2'b00;
		end
		else begin
			case (state)
				S0 : begin
					count1 <= count1 +1;
					count2 <= count2;
					count3 <= count3;
					end
				S1 : begin
					count2 <= count2 + 1;
					count3 <= 2'b00;
					count1 <= count1;
					end
				S2 : begin
					count3 <= count3 + 1;
					count2 <= 4'b0000;
					count1 <= count1;
					end
				default : begin
					count1 <= 6'b000000;
					count2 <= 4'b0000;
					count3 <= 2'b00;
					end
			endcase
		end
	end

	
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    
end


	initial begin
		$fsdbDumpfile("fsm_tb.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	end


    // Test sequence
    initial begin
        // Initialize inputs
        reset = 1;
        #10;
        reset = 0;

        // Wait and observe state transitions
        #1000; // Run simulation for 100ns

        // Finish simulation
		$finish;
	end

    // Monitor the state
    initial begin
        $monitor("Time = %0t: state = %b", $time, state);
    end

endmodule

