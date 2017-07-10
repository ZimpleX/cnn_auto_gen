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
	reg [31:0] data_in_0, data_in_1, data_in_2, data_in_3;
	reg ctrl_in;

	// Outputs
	wire [31:0] data_out_0, data_out_1, data_out_2, data_out_3;
	wire ctrl_out_0, ctrl_out_1, ctrl_out_2, ctrl_out_3;
    wire [3:0] addr_0, addr_1, addr_2, addr_3;
	// Instantiate the Unit Under Test (UUT)
	data_fifo_blk #(.RD_OFFSET(0)) uut_0 (
		.clk(clk), 
		.rst(rst), 
		.data_in(data_in_0), 
		.data_out(data_out_0), 
		.ctrl_in(ctrl_in), 
		.ctrl_out(ctrl_out_0),
		.addr(addr_0)
	);
	data_fifo_blk #(.RD_OFFSET(4)) uut_1 (
		.clk(clk), 
		.rst(rst), 
		.data_in(data_in_1), 
		.data_out(data_out_1), 
		.ctrl_in(ctrl_in), 
		.ctrl_out(ctrl_out_1),
		.addr(addr_1)
	);
	data_fifo_blk #(.RD_OFFSET(8)) uut_2 (
		.clk(clk), 
		.rst(rst), 
		.data_in(data_in_2), 
		.data_out(data_out_2), 
		.ctrl_in(ctrl_in), 
		.ctrl_out(ctrl_out_2),
		.addr(addr_2)
	);
	data_fifo_blk #(.RD_OFFSET(12)) uut_3 (
		.clk(clk), 
		.rst(rst), 
		.data_in(data_in_3), 
		.data_out(data_out_3), 
		.ctrl_in(ctrl_in), 
		.ctrl_out(ctrl_out_3),
		.addr(addr_3)
	);

	integer i,j,f,f_write,f2,f_write_2;
	integer clk_count;
	always #(clock_period/2) clk=~clk;
  always@(posedge clk) begin
    if (ctrl_out_0 == 1) begin
      f_write <= 1;
    end
    if (f_write == 1) begin
      $fwrite(f, "[%d]: %d %d %d %d\n", clk_count, data_out_0, data_out_1, data_out_2, data_out_3);
    end
    if (ctrl_in == 1) begin
        f_write_2 <= 1;
    end
    if (f_write_2 == 1) begin
        $fwrite(f2, "[%d]: %d %d %d %d\n", clk_count, addr_0, addr_1, addr_2, addr_3);
    end
  end
	initial begin
	clk_count = 0;
    f = $fopen("fifo.out", "w");
    f2 = $fopen("fifo_addr.out", "w");
    f_write = 0;
    f_write_2 = 0;
		// Initialize Inputs
		clk = 0;
		rst = 1;
		data_in_0 = 0;
		data_in_1 = 0;
		data_in_2 = 0;
		data_in_3 = 0;
		ctrl_in = 0;

		// Wait 100 ns for global reset to finish
		#100;
		rst = 0;
		ctrl_in = 1;
		for(i=0; i<16; i=i+1)begin
		  #clock_period;
		  clk_count = clk_count + 1;
		  data_in_0 = 4*i+1;
      data_in_1 = 4*i+2;
      data_in_2 = 4*i+3;
      data_in_3 = 4*i+4;
		  ctrl_in = 0;
		end
		for (j=0; j<4; j=j+1) begin
		  ctrl_in = 1;		  
		  for(i=0; i<16; i=i+1)begin
		      #clock_period;
		      clk_count = clk_count + 1;
		      data_in_0 = 4*i+1;
              data_in_1 = 4*i+2;
              data_in_2 = 4*i+3;
              data_in_3 = 4*i+4;
		      ctrl_in = 0;
		  end
		end
		// Add stimulus here
    f_write = 0;
    f_write_2 = 0;
    for (i=0; i<30; i=i+1) begin
        #(clock_period);
        clk_count = clk_count + 1;
    end
    $fclose(f);
    $fclose(f2);
    $finish;
	end
      
endmodule

