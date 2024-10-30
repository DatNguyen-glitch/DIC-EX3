
module Conv_fsm (
    input clk,
    input rst_n,
	input wire [7:0] count_data,
	input wire [3:0] count_line,
	input wire [1:0] count_skip,
    output reg [1:0] state
);

    // State encoding
    parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10;

    // Sequential block to update the state on the clock edge
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S0;
        else begin
			if ((state == S0) & (count_data == 31))
				state <= S1;

			if ((state == S1) & (count_line == 11))
				state <= S2;

			if ((state == S2) & (count_skip == 1))
				state <= S1;
        end
    end

endmodule
