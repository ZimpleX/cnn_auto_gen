`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:20:28 05/14/2013
// Design Name:   data_fifo_blk
// Module Name:   C:/Users/Kevin/software/project/fft_my_design/fft_64/fft_64_disable_BRAM/data_fifo_blk_test.v
// Project Name:  fft_64_disable_BRAM
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: data_fifo_blk
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module data_fifo_blk_test;
    parameter clock_period = 3.0;
	// Inputs
	reg clk;
	reg rst;
	reg [31:0] data_in;
	reg ctrl_in;

	// Outputs
	wire [31:0] data_out;
	wire ctrl_out;

	// Instantiate the Unit Under Test (UUT)
	data_fifo_blk uut (
		.clk(clk), 
		.rst(rst), 
		.data_in(data_in), 
		.data_out(data_out), 
		.ctrl_in(ctrl_in), 
		.ctrl_out(ctrl_out)
	);
    
	integer i;
	always #(clock_period/2) clk=~clk;
	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;
		data_in = 0;
		ctrl_in = 0;

		// Wait 100 ns for global reset to finish
		#100;
		rst = 0;
		data_in = 0;
		ctrl_in = 1;
		
		for(i=0; i<4; i=i+1)begin
		  #clock_period;
		  data_in = 4*i+1;
		  ctrl_in = 0;
		  
		  #clock_period;
		  data_in = 4*i+2;
		  ctrl_in = 0;
		  
		  #clock_period;		  
		  data_in = 4*i+3;
		  ctrl_in = 0;
		  
		  #clock_period;		  
		  data_in = 4*i+4;
		  ctrl_in = 0;		  	  
		end
		
		  ctrl_in = 1;		  
        
		for(i=0; i<4; i=i+1)begin
		  #clock_period;
		  data_in = 4*i+1;
		  ctrl_in = 0;
		  
		  #clock_period;
		  data_in = 4*i+2;
		  ctrl_in = 0;
		  
		  #clock_period;		  
		  data_in = 4*i+3;
		  ctrl_in = 0;
		  
		  #clock_period;		  
		  data_in = 4*i+4;
		  ctrl_in = 0;		  	  
		end
		// Add stimulus here

	end
      
endmodule

