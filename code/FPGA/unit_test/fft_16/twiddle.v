`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:    
// Engineer:       Ren Chen
// 
// Create Date:    17:26:50 01/24/2013 
// Design Name: 
// Module Name:    twiddle 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module twiddle_rom(
clk,
rst,
addr,
data_read,
rd_en
);
parameter ADDR_WIDTH = 2;
parameter ROM_WIDTH = 81;    //3*8+6*9

input clk,rst,rd_en;
input[ADDR_WIDTH-1:0] addr;
output reg[ROM_WIDTH-1:0] data_read;

reg[ROM_WIDTH-1:0] rom[3:0];

always@(posedge clk) begin
  if(rst)
    data_read <= 0;
  else if(rd_en)
    data_read <= rom[addr];
end

///Here the gray coding is used for address generation;
initial begin
 //twiddle_r_b	 twiddle_r_c	 twiddle_r_d	  rpi_b_in   	rmi_b_in  	  rpi_c_in 	    rmi_c_in 	    rpi_d_in 	  rmi_d_in  
 rom[0] = 81'b010000000010000000010000000010000000010000000010000000010000000010000000010000000;                
 rom[1] = 81'b001110110001011011000110001001000101010100111000000000010110101110111011010100111;         
 rom[3] = 81'b001011011000000000110100101000000000010110101110000000010000000101001011000000000;
 rom[2] = 81'b000110001110100101110001010110111011010100111101001011000000000110111011101011001;              
end
endmodule


module twiddle_mul(
clk,
rst,
x_a_in,
y_a_in,
x_b_in,
y_b_in,
x_c_in,
y_c_in,
x_d_in,
y_d_in,
xx_a_out,
yy_a_out,
xx_b_out,
yy_b_out,
xx_c_out,
yy_c_out,
xx_d_out,
yy_d_out,
ctrl_in,
ctrl_out
    );
parameter DATA_WIDTH = 10;    
parameter FACTOR_WIDTH = 9;  
parameter MUL_WIDTH = DATA_WIDTH + FACTOR_WIDTH;    
parameter ROM_WIDTH = 81;
parameter NUM_INPUTS = 8;
parameter MUL_PIPE_STAGE = 1;  

input clk,rst,ctrl_in;
input[DATA_WIDTH-1:0] x_a_in,y_a_in,x_b_in,y_b_in,x_c_in,y_c_in,x_d_in,y_d_in;
output[DATA_WIDTH-3:0] xx_a_out,yy_a_out,xx_b_out,yy_b_out,xx_c_out,yy_c_out,xx_d_out,yy_d_out;
output ctrl_out;
 
/***************************twiddle factor**********************/
wire[FACTOR_WIDTH-1:0] twiddle_r_b;  
wire[FACTOR_WIDTH-1:0] twiddle_r_c;  
wire[FACTOR_WIDTH-1:0] twiddle_r_d;  
wire[FACTOR_WIDTH-1:0] rpi_b_in;     
wire[FACTOR_WIDTH-1:0] rmi_b_in;  
wire[FACTOR_WIDTH-1:0] rpi_c_in;    
wire[FACTOR_WIDTH-1:0] rmi_c_in;  
wire[FACTOR_WIDTH-1:0] rpi_d_in;    
wire[FACTOR_WIDTH-1:0] rmi_d_in; 
wire[ROM_WIDTH-1:0] rom_out;

wire[1:0] addr_rom;
reg[1:0] addr_update;
reg start_update;
wire rd_en;
assign addr_rom = addr_update;

twiddle_rom rom(clk,rst,addr_rom,rom_out,rd_en);  
assign rd_en = ctrl_in||start_update;  

 
always@(posedge clk)   
begin
  if(rst) begin
		start_update <= 1'b0;
		addr_update <= 1'b0;
	end else begin	   
	  if(ctrl_in) begin      
	    start_update <= 1;   
	    addr_update <= 0;    
	  end	
	  else if((start_update == 1)) begin    
		addr_update[1] <= addr_update[0];
	    addr_update[0] <= ~addr_update[1]; 
		if((addr_update==2'b10)) begin
		   start_update <= 0;
	    end
	  end				  
	end
end

assign twiddle_r_b = rom_out[9*FACTOR_WIDTH-1:8*FACTOR_WIDTH];
assign twiddle_r_c = rom_out[8*FACTOR_WIDTH-1:7*FACTOR_WIDTH];
assign twiddle_r_d = rom_out[7*FACTOR_WIDTH-1:6*FACTOR_WIDTH];
assign rpi_b_in = rom_out[6*FACTOR_WIDTH-1:5*FACTOR_WIDTH];
assign rmi_b_in = rom_out[5*FACTOR_WIDTH-1:4*FACTOR_WIDTH];
assign rpi_c_in = rom_out[4*FACTOR_WIDTH-1:3*FACTOR_WIDTH];
assign rmi_c_in = rom_out[3*FACTOR_WIDTH-1:2*FACTOR_WIDTH];
assign rpi_d_in = rom_out[2*FACTOR_WIDTH-1:FACTOR_WIDTH];
assign rmi_d_in = rom_out[FACTOR_WIDTH-1:0];

/************************ do x-y *******************************/ 
reg[DATA_WIDTH-1:0] xbt,ybt,xct,yct,xdt,ydt;
reg[DATA_WIDTH-3:0] xat,yat;          
reg[DATA_WIDTH-1:0] xmyb,xmyc,xmyd;   
wire[DATA_WIDTH-1:0] xmyb_t,xmyc_t,xmyd_t;

always@(posedge clk) begin
  xat <= x_a_in[DATA_WIDTH-3:0];   
  yat <= y_a_in[DATA_WIDTH-3:0];
  xbt <= x_b_in;   
  ybt <= y_b_in;
  xct <= x_c_in;
  yct <= y_c_in;
  xdt <= x_d_in;
  ydt <= y_d_in;
end

  adder #(DATA_WIDTH,DATA_WIDTH,DATA_WIDTH) sub_xmyb(1'b1,xbt,ybt,xmyb_t);
  adder #(DATA_WIDTH,DATA_WIDTH,DATA_WIDTH) sub_xmyc(1'b1,xct,yct,xmyc_t);
  adder #(DATA_WIDTH,DATA_WIDTH,DATA_WIDTH) sub_xmyd(1'b1,xdt,ydt,xmyd_t);
always@(posedge clk)
begin
  xmyb <= xmyb_t;
  xmyc <= xmyc_t;
  xmyd <= xmyd_t;
end

/*********************** do (x-y)*real ******************************/
wire[MUL_WIDTH-1:0] xmyr_b,xmyr_c,xmyr_d;  
reg[FACTOR_WIDTH-1:0] twdl_real_b,twdl_real_c,twdl_real_d;
always@(posedge clk)
begin
    twdl_real_b <= twiddle_r_b;
	twdl_real_c <= twiddle_r_c;
	twdl_real_d <= twiddle_r_d;
end
	mult #(DATA_WIDTH,FACTOR_WIDTH,MUL_PIPE_STAGE) mult_xmy_br(clk,xmyb,twdl_real_b,xmyr_b);
	mult #(DATA_WIDTH,FACTOR_WIDTH,MUL_PIPE_STAGE) mult_xmy_cr(clk,xmyc,twdl_real_c,xmyr_c);
	mult #(DATA_WIDTH,FACTOR_WIDTH,MUL_PIPE_STAGE) mult_xmy_dr(clk,xmyd,twdl_real_d,xmyr_d);
/********************do (real-ima)*y ****************************/
reg[MUL_WIDTH-1:0] rmiy_b,rmiy_c,rmiy_d;    
wire[MUL_WIDTH-1:0] rmiy_b_t,rmiy_c_t,rmiy_d_t;  

	mult #(DATA_WIDTH,FACTOR_WIDTH,MUL_PIPE_STAGE) mult_rmi_by(clk,ybt,rmi_b_in,rmiy_b_t);
	mult #(DATA_WIDTH,FACTOR_WIDTH,MUL_PIPE_STAGE) mult_rmi_cy(clk,yct,rmi_c_in,rmiy_c_t);
	mult #(DATA_WIDTH,FACTOR_WIDTH,MUL_PIPE_STAGE) mult_rmi_dy(clk,ydt,rmi_d_in,rmiy_d_t);

always@(posedge clk)
begin

	rmiy_b <= rmiy_b_t;   
	rmiy_c <= rmiy_c_t;
	rmiy_d <= rmiy_d_t;	  	  
end

/********************do (real+ima)*x ****************************/
reg[MUL_WIDTH-1:0] rpix_b,rpix_c,rpix_d;    
wire[MUL_WIDTH-1:0] rpix_b_t,rpix_c_t,rpix_d_t;
    mult #(DATA_WIDTH,FACTOR_WIDTH,MUL_PIPE_STAGE) mult_bx_rpi(clk,xbt,rpi_b_in,rpix_b_t);
	mult #(DATA_WIDTH,FACTOR_WIDTH,MUL_PIPE_STAGE) mult_cx_rpi(clk,xct,rpi_c_in,rpix_c_t);
	mult #(DATA_WIDTH,FACTOR_WIDTH,MUL_PIPE_STAGE) mult_dx_rpi(clk,xdt,rpi_d_in,rpix_d_t);	
always@(posedge clk)
begin
	rpix_b <= rpix_b_t;
	rpix_c <= rpix_c_t;
	rpix_d <= rpix_d_t;
end    
/***********do real_o = (x-y)*real + (real-ima)*y *******************/
wire[MUL_WIDTH-1:0] real_out_b,real_out_c,real_out_d;
  adder #(MUL_WIDTH,MUL_WIDTH,MUL_WIDTH) add_real_outb(1'b0,xmyr_b,rmiy_b,real_out_b);
  adder #(MUL_WIDTH,MUL_WIDTH,MUL_WIDTH) add_real_outc(1'b0,xmyr_c,rmiy_c,real_out_c);
  adder #(MUL_WIDTH,MUL_WIDTH,MUL_WIDTH) add_real_outd(1'b0,xmyr_d,rmiy_d,real_out_d);
 
/***********do ima_o = (real+ima)*x - (x-y)*real *******************/
wire[MUL_WIDTH-1:0] ima_out_b,ima_out_c,ima_out_d;
  adder #(MUL_WIDTH,MUL_WIDTH,MUL_WIDTH) sub_ima_outb(1'b1,rpix_b,xmyr_b,ima_out_b);
  adder #(MUL_WIDTH,MUL_WIDTH,MUL_WIDTH) sub_ima_outc(1'b1,rpix_c,xmyr_c,ima_out_c);
  adder #(MUL_WIDTH,MUL_WIDTH,MUL_WIDTH) sub_ima_outd(1'b1,rpix_d,xmyr_d,ima_out_d);

reg[DATA_WIDTH-3:0] r_out_a,i_out_a;   
reg[DATA_WIDTH-3:0] r_out_b,i_out_b; 
reg[DATA_WIDTH-3:0] r_out_c,i_out_c; 
reg[DATA_WIDTH-3:0] r_out_d,i_out_d; 

/**************insert registers for pipelining***********************/
localparam PIPE_DEPTH = MUL_PIPE_STAGE + 2;
reg[DATA_WIDTH-3:0] r_out_a_t[PIPE_DEPTH-1:0];   
reg[DATA_WIDTH-3:0] i_out_a_t[PIPE_DEPTH-1:0];
integer k;
always@(posedge clk)
begin
  r_out_a_t[0] <= xat;
  i_out_a_t[0] <= yat;
  for(k=1; k<PIPE_DEPTH; k=k+1) begin
	r_out_a_t[k] <= r_out_a_t[k-1];
    i_out_a_t[k] <= i_out_a_t[k-1];
  end
end

/*************************last pipeline********************************/
always@(posedge clk)
begin
  r_out_a <= r_out_a_t[PIPE_DEPTH-1];    
  i_out_a <= i_out_a_t[PIPE_DEPTH-1];
  r_out_b <= real_out_b[MUL_WIDTH-5:FACTOR_WIDTH-2];   
  i_out_b <= ima_out_b[MUL_WIDTH-5:FACTOR_WIDTH-2];    
  r_out_c <= real_out_c[MUL_WIDTH-5:FACTOR_WIDTH-2];  
  i_out_c <= ima_out_c[MUL_WIDTH-5:FACTOR_WIDTH-2]; 
  r_out_d <= real_out_d[MUL_WIDTH-5:FACTOR_WIDTH-2]; 
  i_out_d <= ima_out_d[MUL_WIDTH-5:FACTOR_WIDTH-2]; 
end

/************************pipeline of ctrl*******************************/
integer j;
reg ctrl_tmp[MUL_PIPE_STAGE+3:0];  
always@(posedge clk)
begin
  ctrl_tmp[0] <= ctrl_in;
	for(j=1; j<MUL_PIPE_STAGE+4; j=j+1)
	  ctrl_tmp[j] <= ctrl_tmp[j-1];
end

assign ctrl_out = ctrl_tmp[MUL_PIPE_STAGE+3];

assign xx_a_out = r_out_a;
assign yy_a_out = i_out_a;
assign xx_b_out = r_out_b;
assign yy_b_out = i_out_b;
assign xx_c_out = r_out_c;
assign yy_c_out = i_out_c;
assign xx_d_out = r_out_d;
assign yy_d_out = i_out_d;

endmodule




