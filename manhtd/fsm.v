
module fsm (
    input clk,
    input reset,
	input wire [5:0] count_data,
	input wire [3:0] count_line,
	input wire [1:0] count_wind,
    output reg [1:0] state
);

    // State encoding
    parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10;

    // Sequential block to update the state on the clock edge
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= S0;
        else begin
			if ((state == S0) & (count_data == 32))
				state <= S1;

			if ((state == S1) & (count_line == 12))
				state <= S2;

			if ((state == S2) & (count_wind == 2))
				state <= S1;
        end
    end

endmodule
