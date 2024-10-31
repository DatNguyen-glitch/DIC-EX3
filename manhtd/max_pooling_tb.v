`ifdef RTL
`include "../verilog/max_pooling.v"
`endif

`ifdef GATE
`include "../gl/max_pooling_SYN.v"
`endif


module max_pooling_tb;

    // Declare inputs as regs and outputs as wires
    reg [35:0] test_val0;
    reg [35:0] test_val1;
    reg [35:0] test_val2;
    reg [35:0] test_val3;
    wire [35:0] max_val;

    // Instantiate the max_pooling module

    max_pooling dut (
        .conv_val0(test_val0),
        .conv_val1(test_val1),
        .conv_val2(test_val2),
        .conv_val3(test_val3),
        .max_val(max_val)
    );

    // Initialize inputs and apply test vectors
    initial begin
        // Monitor the changes
        $monitor("test_val0 = %d, test_val1 = %d, test_val2 = %d, test_val3 = %d, max_val = %d", 
                  test_val0, test_val1, test_val2, test_val3, max_val);

        // Test case 1
        test_val0 = 36'h000000001;
        test_val1 = 36'h000000002;
        test_val2 = 36'h000000003;
        test_val3 = 36'h000000004;
        #10;

        // Test case 2
        test_val0 = 36'h00000000F;
        test_val1 = 36'h00000000A;
        test_val2 = 36'h00000000B;
        test_val3 = 36'h00000000C;
        #10;

        // Test case 3
        test_val0 = 36'h123456789;
        test_val1 = 36'h987654321;
        test_val2 = 36'h111111111;
        test_val3 = 36'h0FFFFFFFF;
        #10;

        // Test case 4
        test_val0 = 36'h555555555;
        test_val1 = 36'h666666666;
        test_val2 = 36'h777777777;
        test_val3 = 36'h088888888;
        #10;

        // Finish the simulation
        $finish;
    end

endmodule

