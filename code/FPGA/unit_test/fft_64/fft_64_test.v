`timescale 1ns / 100ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:26:36 04/29/2013
// Design Name:   fft_opt
// Module Name:   C:/Users/Kevin/software/project/fft_ise/fft/fft_artix/fft_opt_artix/fft_16_blk.v
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
  parameter clk_period = 3.00;   //3 is wrong!!! should be 3.0
	// Inputs
	reg clk;
	reg rst_in;
	reg [15:0] x_a_in;
	reg [15:0] y_a_in;
	reg [15:0] x_b_in;
	reg [15:0] y_b_in;
	reg [15:0] x_c_in;
	reg [15:0] y_c_in;
	reg [15:0] x_d_in;
	reg [15:0] y_d_in;
	reg ctrl_in;

	// Outputs
	wire [15:0] x_a_out;
	wire [15:0] y_a_out;
	wire [15:0] x_b_out;
	wire [15:0] y_b_out;
	wire [15:0] x_c_out;
	wire [15:0] y_c_out;
	wire [15:0] x_d_out;
	wire [15:0] y_d_out;
	wire ctrl_out;

	// Instantiate the Unit Under Test (UUT)
	fft_64_wrapper UUT(
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
		.ctrl_out(ctrl_out)
	);

  always #(clk_period/2) clk=~clk;
	
	integer i,j;
  integer data_file,scan_file;
  reg [3:0] count;
	initial begin
		// Initialize Inputs
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
		count = 0;
	  //#(clk_period);
	  /*
    $display("start");
    data_file = $fopen("data_file_0.txt", "r");
 	 	$display("data file %d\n", data_file);
		if (data_file == 0) begin
    		$display("data_file handle was NULL");
    		$finish;
  	end
  	while (!$feof(data_file)) begin
        count = count + 1;
        scan_file = $fscanf(data_file, "%h %h %h %h\n", x_a_in, x_b_in, x_c_in, x_d_in);
        y_a_in = 0;
        y_b_in = 0;
        y_c_in = 0;
        y_d_in = 0;
        ctrl_in = (count==0)? 1:0;
        #(clk_period);
    end
    $fclose(data_file);*/
    
		for(j=0; j<2; j=j+1)begin
			for(i=0; i<15; i=i+1) begin
				#(clk_period);
				x_a_in = (i==0)?1:0;//$random()%((1<<8)-1);
				y_a_in = 0;
				x_b_in = 0;//$random()%((1<<8)-1);
				y_b_in = 0;
				x_c_in = 0;//$random()%((1<<8)-1);
				y_c_in = 0;
				x_d_in = 0;//$random()%((1<<8)-1);
				y_d_in = 0;
				ctrl_in = 0;
			end
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
		end
		
			
			//#(clk_period);
		    x_a_in = 0;
			y_a_in = 0;
			x_b_in = 0;
			y_b_in = 0;
			x_c_in = 0;
			y_c_in = 0;
			x_d_in = 0;
			y_d_in = 0;
			ctrl_in = 0;
			#(3*clk_period);
			
		// Add stimulus here

	end
      
endmodule

// x_a_in = 0;
			// y_a_in = 0;
			// x_b_in = 1;
			// y_b_in = 0;
			// x_c_in = 2;
			// y_c_in = 0;
			// x_d_in = 3;
			// y_d_in = 0;
			// ctrl_in = 0;
			// #(clk_period);
			
			// x_a_in = 4;
			// y_a_in = 0;
			// x_b_in = 5;
			// y_b_in = 0;
			// x_c_in = 6;
			// y_c_in = 0;
			// x_d_in = 7;
			// y_d_in = 0;
			// ctrl_in = 0;
			// #(clk_period);
			
			// x_a_in = 8;
			// y_a_in = 0;
			// x_b_in = 9;
			// y_b_in = 0;
			// x_c_in = 10;
			// y_c_in = 0;
			// x_d_in = 11;
			// y_d_in = 0;
			// ctrl_in = 0;
			// #(clk_period);
			
			// x_a_in = 12;
			// y_a_in = 0;
			// x_b_in = 13;
			// y_b_in = 0;
			// x_c_in = 14;
			// y_c_in = 0;
			// x_d_in = 15;
			// y_d_in = 0;
			// ctrl_in = 1;
			// #(clk_period);
