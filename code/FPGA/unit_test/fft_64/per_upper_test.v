`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:27:13 05/14/2013
// Design Name:   pmt_upper_com
// Module Name:   C:/Users/Kevin/software/project/fft_my_design/fft_64/fft_64_disable_BRAM/per_upper_test.v
// Project Name:  fft_64_disable_BRAM
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: pmt_upper_com
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module per_upper_test;
    parameter clk_period = 6;
	// Inputs
	reg clk;
	reg rst;
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

	// Instantiate the Unit Under Test (UUT)
	pmt_lower_com uut (
		.clk(clk), 
		.rst(rst), 
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
   
    always #(clk_period/2) clk = ~clk;
	
	integer i;
	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;
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
		#(clk_period*20);
		#(clk_period/2);
		#(0.5);
		
		rst = 0;
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
		
		for(i=0; i<16; i=i+1) begin		
			x_a_in = 1;
			y_a_in = 0;
			x_b_in = 2;
			y_b_in = 0;
			x_c_in = 3;
			y_c_in = 0;
			x_d_in = 4;
			y_d_in = 0;
			ctrl_in = 0;
			#(clk_period);
			
			x_a_in = 5;
			y_a_in = 0;
			x_b_in = 6;
			y_b_in = 0;
			x_c_in = 7;
			y_c_in = 0;
			x_d_in = 8;
			y_d_in = 0;
			ctrl_in = 0;
			#(clk_period);
			
			x_a_in = 9;
			y_a_in = 0;
			x_b_in = 10;
			y_b_in = 0;
			x_c_in = 11;
			y_c_in = 0;
			x_d_in = 12;
			y_d_in = 0;
			ctrl_in = 0;
			#(clk_period);
			
			x_a_in = 13;
			y_a_in = 0;
			x_b_in = 14;
			y_b_in = 0;
			x_c_in = 15;
			y_c_in = 0;
			x_d_in = 16;
			y_d_in = 0;
			ctrl_in = 1;
			#(clk_period);
		end        
		// Add stimulus here

	end
      
endmodule

