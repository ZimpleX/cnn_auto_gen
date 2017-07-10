`timescale 1ns/100ps

module test_bench;
    parameter clk_period = 3.00;
	 parameter DATA_WIDTH = 16;
    reg clk,rst;
    reg[15:0] input_stream[3:0];
    wire[15:0] output_stream[3:0];
    reg valid_in;
    wire valid_out;

	 
    spn #(.DATA_WIDTH(DATA_WIDTH)) UUT(
        .clk(clk),
        .rst(rst),
        .input_stream(input_stream),
        .output_stream(output_stream),
        .valid_in(valid_in),
        .valid_out(valid_out)
    );

    always #(clk_period/2) clk=~clk;

    integer input_file,output_file,scan;
    integer i,j;
    
    initial begin
		  clk = 0;
        rst = 1;
        #(10*clk_period);
        rst = 0;
        #(clk_period);
        $display("start");
        input_file = $fopen("input_file.txt","r");
        output_file = $fopen("output_file.txt","w");
        if (input_file == 0 || output_file == 0) begin
            $display("in/output file handle was NULL");
            $finish;
        end
        while (!$feof(input_file)) begin
            // NOTE: valid in should be a clk before the real input data
            scan = $fscanf(input_file, "%d %d %d %d - %d\n",
                    input_stream[0],input_stream[1],
                    input_stream[2],input_stream[3],valid_in);
            #(clk_period);
        end
        for (i=0;i<4;i=i+1) begin
            input_stream[i] = 0;
        end
        valid_in = 1;
        #(260*clk_period);
        $fclose(output_file);
        $fclose(input_file);
        $finish;
    end

    always@(negedge clk) begin
        if (output_file != 0) begin
            $fwrite(output_file,"%d    %d    %d    %d    - %d\n",
                output_stream[0],output_stream[1],
                output_stream[2],output_stream[3],valid_out);
		  end
    end

endmodule
