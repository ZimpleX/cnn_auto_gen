`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:21:17 03/01/2013 
// Design Name:    Ren Chen
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


//This read and write into the same address
//no need for ping pong mechanism, just update the address
//This fifo use dist. RAM
module data_fifo_distRAM(
clk,
rst,
data_in,
data_out,
ctrl_in,
ctrl_out);
//For N=16, RD_OFFSET = 0,1,2,3;
//For N=64, RD_OFFSET = 0,4,8,12;
parameter RD_OFFSET = 2'b00;       //offset of start address of different data buffers
parameter DATA_WIDTH = 32;         //it supports two simultaenous read
parameter ADDR_WIDTH = 2;          // 2^? = N/4;
parameter PROBLEM_SIZE = 16;       //problem size of N-point FFT
parameter UPDATE_OFFSET = 1'b1;    //=N/16, if N=16, equals to 1; if N=64, then equals to 4;

//Be carefuly with update_distance and width_counter, as counter=counter+1;
//when N=16, UPDATE_DISTANCE = 1, WIDTH_COUNTER = 1;
//when N=64, UPDATE_DISTANCE = 1, WIDTH_COUNTER = 1;
parameter UPDATE_DISTANCE = 1'b1;  //=1, when N=16; =3(11), when N=64; =15(1111), when N=256;
parameter WIDTH_COUNTER = 1;       //2^?=N/16; equals to 1, when N=16; equals to 2, when N=64;
parameter VALUE_FLAG_COUNTER = 1'b0;      //equals to 1 then counter is used
parameter DEPTH = 1<<ADDR_WIDTH;   //
integer i;

input  clk, rst, ctrl_in;
input [DATA_WIDTH-1:0] data_in;
output reg[DATA_WIDTH-1:0] data_out;
output reg ctrl_out;
reg[ADDR_WIDTH-1:0] addr;
  
///////////////////////Use Dist RAM Here/////////////////////////////////////////////
reg wen, addr_offset;  //addr_offset = flag of addition or subtraction
//N=16, width_addr = 2 (2^2=4=N/4);
//N=64, width_addr = 4 (2^4=16=N/4);
//reg[ADDR_WIDTH-1:0] addr;
reg[WIDTH_COUNTER-1:0] counter;
//need optimization, when flag_counter=0, then counter is not used;
reg flag_counter;
reg ctrl_tmp[3:0];
//reg []

//reg[DATA_WIDTH-1:0] data_rd;
wire[DATA_WIDTH-1:0] din;
wire[DATA_WIDTH-1:0] dout;

assign din = data_in;
dist_ram #(DATA_WIDTH,ADDR_WIDTH) ram(clk,wen,addr,din,dout);

/////////////address update/////////////////////////
wire[ADDR_WIDTH-1:0] addr_update;
//addr_offset=0, then addr=addr - 1 or N/16; addr_offset=1,then addr=addr + 1 or N/16;
assign addr_update = ((addr_offset) ?(addr+UPDATE_OFFSET) :(addr-UPDATE_OFFSET));  

always@(posedge clk)
begin
  if(rst) begin
		wen <= 1'b0;
		addr <= 2'b11;   
		//when N=16, initial addr = 3, for different buffers, start with 3+1, 3+2, 3+3, 3+0 (0,1,2,3) start with -1
		//           (RD_OFFSET=0,1,2,3); addr = addr +/- 1; 
		//when N=64, initial addr = 15, for different buffers, start with 15+1, 15+5, 15+9, 15+13; (RD_OFFSET=0,4,8,12); addr = addr-4;        
		addr_offset <= 1'b1;
		counter <= 0;
		flag_counter <= VALUE_FLAG_COUNTER;
		//data_rd <= 0;
	end
	else begin
	   data_out <= dout;
	   //When N=16, UPDATE_DISTANCE=1, no distance update.
	   
	   counter <= ((flag_counter==1'b1) ?(counter + 1) :counter);
	  //A is in use or B is in use, after write A, statusA=1 until start to write B
		if(ctrl_in) begin
		  wen <= 1;
		  //if addr_offeset== 1; addr = addr + 0/4/8/12 +1 for N =64;
		  //if addr_offeset== 0; addr = addr - 0/4/8/12 -(8-1) for N =64;
		  addr <= (!addr_offset) ?(addr-RD_OFFSET-((PROBLEM_SIZE/8)-1)) :(addr+RD_OFFSET+1);  
		  //addr_offset=0, then addr=addr-1; addr_offset=1,then addr=addr+1; need optimization
		  addr_offset <= ~addr_offset;
		  counter <= 0;
		end else if(counter == UPDATE_DISTANCE) begin   
		  //when N=64, RD_OFFSET=4, then address:0->12->8->4; ->1->13->9->5; ->2->14->10->6;
		  //here update_distance = 3 when N=64;
		  addr <= addr_update + 1;
		end
		else   // when N=16, addr +/- 1, When N=64, addr +/- 4
		  addr <= addr_update;
		//if start to be used then write 3 more times
		///////////////////////////address update///////////////////////		
		ctrl_tmp[0] <= ctrl_in;
		for(i=0; i<3; i=i+1)
		  ctrl_tmp[i+1] <= ctrl_tmp[i];
		//ctrl_out <= (wen)?(ctrl_in):1'b0;
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



//This data_fifo_blk can enable or disable BRAM

//This read and write into the same address
//no need for ping pong mechanism, just update the address
//This fifo use block RAM
module data_fifo_blk(
clk,
rst,
data_in,
data_out,
ctrl_in,
ctrl_out,
addr);
//For N=16, RD_OFFSET = 0,1,2,3;
//For N=64, RD_OFFSET = 0,4,8,12;
parameter RD_OFFSET = 2'b00;       //offset of start address of different data buffers
parameter DATA_WIDTH = 32;         //it supports two simultaenous read
parameter ADDR_WIDTH = 4;          // 2^? = N/4;
parameter PROBLEM_SIZE = 64;       //problem size of N-point FFT
parameter UPDATE_OFFSET = 4;    //=N/16, if N=16, equals to 1; if N=64, then equals to 4;
parameter RAM_WIDTH = DATA_WIDTH*2;

//Be carefuly with update_distance and width_counter, as counter=counter+1;
//when N=16, UPDATE_DISTANCE = 1, WIDTH_COUNTER = 1;
//when N=64, UPDATE_DISTANCE = 1, WIDTH_COUNTER = 1;
parameter UPDATE_DISTANCE = 3;  //=1, when N=16; =3(11), when N=64; =15(1111), when N=256;
parameter WIDTH_COUNTER = 2;       //2^?=N/16; equals to 1, when N=16; equals to 2, when N=64;
parameter VALUE_FLAG_COUNTER = 1'b1;      //equals to 1 then counter is used
parameter DEPTH = 1<<ADDR_WIDTH;   //

integer i;

input  clk, rst, ctrl_in;
input [DATA_WIDTH-1:0] data_in;
output [DATA_WIDTH-1:0] data_out;
output reg ctrl_out;
output reg[ADDR_WIDTH-1:0] addr;
///////////////////////Use Bram Here/////////////////////////////////////////////
reg wen, addr_offset;  //addr_offset = flag of addition or subtraction
//N=16, width_addr = 2 (2^2=4=N/4);
//N=64, width_addr = 4 (2^4=16=N/4);
reg[WIDTH_COUNTER-1:0] counter;
reg[ADDR_WIDTH-1:0] counter_ctrl;
//need optimization, when flag_counter=0, then counter is not used;
reg flag_counter;
reg ctrl_tmp[3:0];
//reg []
//reg[DATA_WIDTH-1:0] data_rd;
wire[DATA_WIDTH-1:0] din;
wire[DATA_WIDTH-1:0] dout;

assign din = data_in;
blk_ram #(DATA_WIDTH,ADDR_WIDTH) ram(clk,wen,1'b1,addr,din,dout);

/////////////address update/////////////////////////
wire[ADDR_WIDTH-1:0] addr_update;
//addr_offset=0, then addr=addr - 1 or N/16; addr_offset=1,then addr=addr + 1 or N/16;
assign addr_update = ((addr_offset) ?(addr+UPDATE_OFFSET) :(addr-UPDATE_OFFSET));  

always@(posedge clk)
begin
  if(rst) begin
		wen <= 1'b0;
		addr <= 4'b1111;    //addr = N/4-1; 
		//when N=16, initial addr = 3, for different buffers, start with 3+1, 3+2, 3+3, 3+0 (0,1,2,3) start with -1
		//           (RD_OFFSET=0,1,2,3); addr = addr +/- 1; 
		//when N=64, initial addr = 15, for different buffers, start with 15+1, 15+5, 15+9, 15+13; (RD_OFFSET=0,4,8,12); addr = addr-4;        
		addr_offset <= 1'b1;
		counter <= 0;
		flag_counter <= VALUE_FLAG_COUNTER;
		ctrl_out <= 0;
		counter_ctrl <= 1;
		//data_rd <= 0;
	end
	else begin
	   //When N=16, UPDATE_DISTANCE=1, no distance update.
   
	   counter <= ((flag_counter==1'b1) ?(counter + 1) :counter);
	  //A is in use or B is in use, after write A, statusA=1 until start to write B
		if(ctrl_in) begin
		  wen <= 1;
		  //if addr_offeset== 1; addr = addr + 0/4/8/12 +1 for N =64;
		  //if addr_offeset== 0; addr = addr - 0/4/8/12 -(8-1) for N =64;
		  addr <= (!addr_offset) ?(addr-RD_OFFSET-((PROBLEM_SIZE/8)-1)) :(addr+RD_OFFSET+1);  
		  //addr_offset=0, then addr=addr-1; addr_offset=1,then addr=addr+1; need optimization
		  addr_offset <= ~addr_offset;
		  counter <= 0;
		end else if(counter == UPDATE_DISTANCE) begin   
		  //when N=64, RD_OFFSET=4, then address:0->12->8->4; ->1->13->9->5; ->2->14->10->6;
		  //here update_distance = 3 when N=64;
		  addr <= addr_update + 1;
		end
		else   // when N=16, addr +/- 1, When N=64, addr +/- 4
		  addr <= addr_update;
		//if start to be used then write 3 more times
		///////////////////////////address update///////////////////////
		if(ctrl_in||(!wen))
		  counter_ctrl <= 0;
		else
		  counter_ctrl <= counter_ctrl + 1;	
		  
		ctrl_out <= ((counter_ctrl == 4'b1111) ?1'b1 : 1'b0);
		  
		
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
	begin
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
