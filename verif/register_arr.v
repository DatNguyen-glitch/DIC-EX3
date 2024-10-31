
module register_arr (
    input wire clk,
    input wire rst_n,
    input wire [3:0] addr_row,
    input wire [3:0] addr_col,
    input wire [35:0] data_in,
    input wire write_en,
    input wire read_en,
    output wire [35:0] data_out
);
	wire read_allow;
    reg [35:0] registers [0:11][0:11];
    reg [35:0] read_data;
    integer i, j;

    // Reset process
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 12; i = i + 1) begin
            	for (j = 0; j < 12; j = j + 1) begin
                	registers[i][j] <= 0;
		end
            end
        end
		else begin
			if (write_en) begin
    	        		registers[addr_row][addr_col] <= data_in;
        		end
		end
    end

	assign read_allow = write_en ? 1'b0 : read_en;

    // Read process
    always @(posedge clk) begin
		if (!rst_n)
            read_data <= 0;
      	else if (read_allow)
            read_data <= registers[addr_row][addr_col];
		else
			read_data <= 36'b0;
    end

    assign data_out = read_data;

endmodule
