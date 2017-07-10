`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:       Ren Chen
// 
// Create Date:    10:21:17 03/01/2013 
// Design Name:    
// Module Name:    Data Buffer 
// Project Name:   TAPAS
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// 3/13 wrong output of ctrl_out, two methods:1. write into RAM 2. keep good input
//
//////////////////////////////////////////////////////////////////////////////////
module data_fifo_wrapper(
clk,
rst,
data_in,
data_out,
ctrl_in,
ctrl_out);
parameter DATA_WIDTH = 32;

input clk,rst,ctrl_in;
input[DATA_WIDTH-1:0] data_in;
output reg[DATA_WIDTH-1:0] data_out;
output reg ctrl_out;

reg[DATA_WIDTH-1:0] data_in_reg;
reg ctrl_in_reg;
wire[DATA_WIDTH-1:0] dout;
wire ctl_out;

data_fifo_blk #(1,DATA_WIDTH,2) fifo_a(clk,rst,data_in_reg,dout,ctrl_in_reg,ctl_out);

always@(posedge clk)
begin
  data_in_reg <= data_in;
	ctrl_in_reg <= ctrl_in;
	data_out <= dout;
	ctrl_out <= ctl_out;
end

endmodule



module data_fifo_distRAM(
clk,
rst,
data_in,
data_out,
ctrl_in,
ctrl_out);
parameter RD_OFFSET = 2'b00;       
parameter DATA_WIDTH = 32;         
parameter ADDR_WIDTH = 2;          
parameter PROBLEM_SIZE = 16;       
parameter UPDATE_OFFSET = 1'b1;    


parameter UPDATE_DISTANCE = 1'b1;       
parameter WIDTH_COUNTER = 1;            
parameter VALUE_FLAG_COUNTER = 1'b0;    
parameter DEPTH = 1<<ADDR_WIDTH;   
integer i;

input  clk, rst, ctrl_in;
input [DATA_WIDTH-1:0] data_in;
output reg[DATA_WIDTH-1:0] data_out;
output reg ctrl_out;
  
///////////////////////Use Dist RAM Here/////////////////////////////////////////////
reg wen, addr_offset;  //addr_offset = flag of addition or subtraction
reg[ADDR_WIDTH-1:0] addr;
reg[WIDTH_COUNTER-1:0] counter;
reg flag_counter;
reg ctrl_tmp[3:0];

wire[DATA_WIDTH-1:0] din;
wire[DATA_WIDTH-1:0] dout;

assign din = data_in;
dist_ram #(DATA_WIDTH,ADDR_WIDTH) ram(clk,wen,addr,din,dout);

/////////////address update/////////////////////////
wire[ADDR_WIDTH-1:0] addr_update;
assign addr_update = ((addr_offset) ?(addr+UPDATE_OFFSET) :(addr-UPDATE_OFFSET));  

always@(posedge clk)
begin
  if(rst) begin
		wen <= 1'b0;
		addr <= 2'b11;   	
		addr_offset <= 1'b1;
		counter <= 0;
		flag_counter <= VALUE_FLAG_COUNTER;
	end
	else begin
	   data_out <= dout;	   
	   counter <= ((flag_counter==1'b1) ?(counter + 1) :counter);
		if(ctrl_in) begin
		  wen <= 1;
		  addr <= (!addr_offset) ?(addr-RD_OFFSET-((PROBLEM_SIZE/8)-1)) :(addr+RD_OFFSET+1);  
		  addr_offset <= ~addr_offset;
		  counter <= 0;
		end else if(counter == UPDATE_DISTANCE) begin   
		  addr <= addr_update + 1;
		end
		else   // when N=16, addr +/- 1, When N=64, addr +/- 4
		  addr <= addr_update;
		///////////////////////////address update///////////////////////		
		ctrl_tmp[0] <= ctrl_in;
		for(i=0; i<3; i=i+1)
		  ctrl_tmp[i+1] <= ctrl_tmp[i];
		ctrl_out <= ctrl_tmp[3];
	end
end

endmodule

//////////////////////////////////////////////////////////////
module dist_ram(
clk,
wen,
addr,
din,
dout
);
parameter DATA_WIDTH = 32;
parameter ADDR_RAM = 2;
parameter SIZE_RAM = 1<<ADDR_RAM;

input clk,wen;
input[ADDR_RAM-1:0] addr;
input[DATA_WIDTH-1:0] din;
output[DATA_WIDTH-1:0] dout;

reg[DATA_WIDTH-1:0] ram[SIZE_RAM-1:0];

always@(posedge clk)
begin
  if(wen)
	  ram[addr] <= din;
end

assign dout = ram[addr];

integer i;
initial begin
for(i=0; i<SIZE_RAM; i=i+1)
begin
  ram[i] = 0;
end
end
endmodule


module data_fifo_blk(
clk,
rst,
data_in,
data_out,
ctrl_in,
ctrl_out,
addr);
  parameter RD_OFFSET = 2'b00;      
  parameter DATA_WIDTH = 32;        
  parameter ADDR_WIDTH = 2;         
  parameter PROBLEM_SIZE = 16;      
  // UPDATE_OFFSET: stride? P_i in the paper?
  parameter UPDATE_OFFSET = 1'b1;   

  parameter UPDATE_DISTANCE = 1'b1;      
  parameter WIDTH_COUNTER = 1;           
  parameter VALUE_FLAG_COUNTER = 1'b0;   
  parameter DEPTH = 1<<ADDR_WIDTH;   

  integer i;

  input  clk, rst, ctrl_in;
  input [DATA_WIDTH-1:0] data_in;
  output [DATA_WIDTH-1:0] data_out;
  output reg ctrl_out;
  output reg [ADDR_WIDTH-1:0] addr;
  ///////////////////////Use Bram Here/////////////////////////////////////////////
  reg wen, addr_offset;  
  //reg[ADDR_WIDTH-1:0] addr;
  reg[WIDTH_COUNTER-1:0] counter;
  reg flag_counter;
  reg ctrl_tmp[3:0];
  wire[DATA_WIDTH-1:0] din;
  wire[DATA_WIDTH-1:0] dout;

  assign din = data_in;
  blk_ram #(DATA_WIDTH,ADDR_WIDTH) ram(clk,wen,1'b1,addr,din,dout);

  /////////////address update/////////////////////////
  wire[ADDR_WIDTH-1:0] addr_update;
  assign addr_update = ((addr_offset) ?(addr+UPDATE_OFFSET) :(addr-UPDATE_OFFSET));  

  always@(posedge clk)
  begin
    if(rst) begin
      wen <= 1'b0;
      addr <= 2'b11;         
      addr_offset <= 1'b1;
      counter <= 0;
      flag_counter <= VALUE_FLAG_COUNTER;
    end
    else begin
      counter <= ((flag_counter==1'b1) ?(counter + 1) :counter);
      if(ctrl_in) begin
        wen <= 1;
        addr <= (!addr_offset) ?(addr-RD_OFFSET-((PROBLEM_SIZE/8)-1)) :(addr+RD_OFFSET+1);  
        addr_offset <= ~addr_offset;
        counter <= 0;
      end else if(counter == UPDATE_DISTANCE) begin   
        addr <= addr_update + 1;
      end
      else   
        addr <= addr_update;
        ///////////////////////////address update///////////////////////		
      ctrl_tmp[0] <= ctrl_in;
      for(i=0; i<3; i=i+1)
        ctrl_tmp[i+1] <= ctrl_tmp[i];
      ctrl_out <= ctrl_tmp[3];
    end
end

assign data_out = dout;
endmodule


module blk_ram(
clk,
wen,
en,
addr,
din,
dout
);
  parameter DATA_WIDTH = 16;
  parameter ADDR_RAM = 11;
  parameter SIZE_RAM = 1<<ADDR_RAM;

  input clk,wen,en;
  input[ADDR_RAM-1:0] addr;
  input[DATA_WIDTH-1:0] din;
  output reg[DATA_WIDTH-1:0] dout;

  reg[DATA_WIDTH-1:0] ram[SIZE_RAM-1:0];

  always@(posedge clk)
  begin
    if(en)   //enable signal
    begin     // the write before read design
      if(wen)
        ram[addr] <= din;
      dout <= ram[addr];
    end
  end

  integer i;
  initial begin
  for(i=0; i<SIZE_RAM; i=i+1)
  begin
    ram[i] = 0;
  end
  end
endmodule
