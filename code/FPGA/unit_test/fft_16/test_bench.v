`timescale 1ns / 100ps


////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:26:36 04/29/2013
// Design Name:   fft_opt
// Project Name:  fft_opt_artix
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: fft_opt
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test_bench;
  parameter clk_period = 3.00;   
	// Inputs
	reg clk;
	reg rst_in;
	reg [7:0] x_a_in;
	reg [7:0] y_a_in;
	reg [7:0] x_b_in;
	reg [7:0] y_b_in;
	reg [7:0] x_c_in;
	reg [7:0] y_c_in;
	reg [7:0] x_d_in;
	reg [7:0] y_d_in;
	reg ctrl_in;

	// Outputs
	wire [7:0] x_a_out;
	wire [7:0] y_a_out;
	wire [7:0] x_b_out;
	wire [7:0] y_b_out;
	wire [7:0] x_c_out;
	wire [7:0] y_c_out;
	wire [7:0] x_d_out;
	wire [7:0] y_d_out;
	wire ctrl_out;
	wire [1:0] addr_0;
	wire [1:0] addr_1;
	wire [1:0] addr_2;
	wire [1:0] addr_3;

	// Instantiate the Unit Under Test (UUT)
	// =======================================
	// Testing FFT with BRAM  ================
	// =======================================
	fft_opt_16_bram UUT(
		.clk(clk), 
		.rst_in(rst_in), 
		.x_a_in(x_a_in), 
		.y_a_in(y_a_in), 
		.x_b_in(x_b_in), 
		.y_b_in(y_b_in), 
		.x_c_in(x_c_in), 
		.y_c_in(y_c_in), 
		.x_d_in(x_d_in), 
		.y_d_in(y_d_in), 
		.x_a_out(x_a_out), 
		.y_a_out(y_a_out), 
		.x_b_out(x_b_out), 
		.y_b_out(y_b_out), 
		.x_c_out(x_c_out), 
		.y_c_out(y_c_out), 
		.x_d_out(x_d_out), 
		.y_d_out(y_d_out), 
		.ctrl_in(ctrl_in), 
		.ctrl_out(ctrl_out),
		.addr_0(addr_0),
		.addr_1(addr_1),
		.addr_2(addr_2),
		.addr_3(addr_3)
	);

    always #(clk_period/2) clk=~clk;
	
	integer i,j;
	integer input_file,scan_file,output_file;
	integer start_output;
	reg [1:0] count;	// count 4, cuz total of 4 sets of inputs are 4 x 4 = 16.
	initial begin
		// Initialize Inputs
		start_output = 0;
		output_file = 0;
		input_file = 0;
		count = 0;
		clk = 0;
		rst_in = 1;
		x_a_in = 0;
		y_a_in = 0;
		x_b_in = 0;
		y_b_in = 0;
		x_c_in = 0;
		y_c_in = 0;
		x_d_in = 0;
		y_d_in = 0;
		ctrl_in = 0;
		// Wait 100 ns for global reset to finish
		#(20*clk_period);
		rst_in = 0;
		#(clk_period);
		
		#(clk_period/2);
		#(0.5);
		
		x_a_in = 0;
		y_a_in = 0;
		x_b_in = 0;
		y_b_in = 0;
		x_c_in = 0;
		y_c_in = 0;
		x_d_in = 0;
		y_d_in = 0;
		ctrl_in = 1;
		#(clk_period);
		
		//logic   signed [21:0] captured_data;
      $display("start");
	 	input_file = $fopen("input_file.txt", "r");
      output_file = $fopen("output_file.txt","w");
		if (input_file == 0 || output_file == 0) begin
    		$display("input_file or output_file handle was NULL");
    		$finish;
  		end
  		while (!$feof(input_file)) begin
  			 count = count+1;
  		    scan_file = $fscanf(input_file, "%h %h %h %h\n", x_a_in, x_b_in, x_c_in, x_d_in);
			 $display("get data %d %d %d %d", x_a_in,x_b_in,x_c_in,x_d_in);
          y_a_in = 0;
          y_b_in = 0;
          y_c_in = 0;
          y_d_in = 0;
          ctrl_in = (count==0)? 1:0;
          # (clk_period);
  		end
        x_a_in = 0;
        x_b_in = 0;
        x_c_in = 0;
        x_d_in = 0;
        y_a_in = 0;
        y_b_in = 0;
        y_c_in = 0;
        y_d_in = 0;
        ctrl_in = 0;
        #(40*clk_period);
        $fclose(output_file);
			$fclose(input_file);
			$finish;
  end

	always@(negedge clk) begin
		if (ctrl_in == 1)begin
			start_output <= 1;
		end
		if (start_output == 1  && output_file != 0) begin
			$fwrite(output_file,"%d,%d    %d,%d    %d,%d    %d,%d\n",x_a_out,y_a_out,x_b_out,y_b_out,x_c_out,y_c_out,x_d_out,y_d_out);
		end
	end
endmodule

/*  Ren's test cases
 
		for(i=0; i<1500; i=i+1) begin
			x_a_in = 1;//$random()%((1<<8)-1);
			y_a_in = 0;
			x_b_in = 0;//$random()%((1<<8)-1);
			y_b_in = 0;
			x_c_in = 0;//$random()%((1<<8)-1);
			y_c_in = 0;
			x_d_in = 0;//$random()%((1<<8)-1);
			y_d_in = 0;
			ctrl_in = 0;
			#(clk_period);
			
			x_a_in = 0;//$random()%((1<<8)-1);
			y_a_in = 0;
			x_b_in = 0;//$random()%((1<<8)-1);
			y_b_in = 0;
			x_c_in = 0;//$random()%((1<<8)-1);
			y_c_in = 0;
			x_d_in = 0;//$random()%((1<<8)-1);
			y_d_in = 0;
			ctrl_in = 0;
			#(clk_period);
			
			x_a_in = 0;//$random()%((1<<8)-1);
			y_a_in = 0;
			x_b_in = 0;//$random()%((1<<8)-1);
			y_b_in = 0;
			x_c_in = 0;//$random()%((1<<8)-1);
			y_c_in = 0;
			x_d_in = 0;//$random()%((1<<8)-1);
			y_d_in = 0;
			ctrl_in = 0;
			#(clk_period);
			
			x_a_in = 0;//$random()%((1<<8)-1);
			y_a_in = 0;
			x_b_in = 0;//$random()%((1<<8)-1);
			y_b_in = 0;
			x_c_in = 0;//$random()%((1<<8)-1);
			y_c_in = 0;
			x_d_in = 0;//$random()%((1<<8)-1);
			y_d_in = 0;
			ctrl_in = 1;
			#(clk_period);
		end

		  x_a_in = 0;
			y_a_in = 0;
			x_b_in = 0;
			y_b_in = 0;
			x_c_in = 0;
			y_c_in = 0;
			x_d_in = 0;
			y_d_in = 0;
			ctrl_in = 0;
			#(30*clk_period);
            $finish;
			
		// Add stimulus here

	end
endmodule

*/