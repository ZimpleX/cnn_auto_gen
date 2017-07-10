`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    03:23:20 03/23/2013 
// Design Name: 
// Module Name:    fft_opt 
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
module fft_16_wrapper(
clk,
rst_in,
x_a_in,
y_a_in,
x_b_in,
y_b_in,
x_c_in,
y_c_in,
x_d_in,
y_d_in,
x_a_out,
y_a_out,
x_b_out,
y_b_out,
x_c_out,
y_c_out,
x_d_out,
y_d_out,
ctrl_in,
ctrl_out
);
localparam DATA_WIDTH = 8;
localparam PROBLEM_SIZE = 16;
localparam NUM_CHANNELS = 4;
localparam NUM_INPUTS = 2*NUM_CHANNELS;

input clk,rst_in,ctrl_in;	
//input[DATA_WIDTH-1:0]	data_in;
//output[DATA_WIDTH-1:0]	data_out;

/********************************************/
input[DATA_WIDTH-1:0] x_a_in,y_a_in,x_b_in,y_b_in
                     ,x_c_in,y_c_in,x_d_in,y_d_in;

output reg[DATA_WIDTH-1:0] x_a_out,y_a_out,x_b_out,y_b_out
                          ,x_c_out,y_c_out,x_d_out,y_d_out;
output reg ctrl_out;

reg[DATA_WIDTH-1:0]   x_a_in_reg,y_a_in_reg,x_b_in_reg,y_b_in_reg
                     ,x_c_in_reg,y_c_in_reg,x_d_in_reg,y_d_in_reg;
//assign data_in = in[DATA_WIDTH-1:0];
//assign data_out = out[DATA_WIDTH-1:0];
wire ctrl_out_wire;
wire[DATA_WIDTH-1:0] x_a_out_w,y_a_out_w,x_b_out_w,y_b_out_w,x_c_out_w,y_c_out_w,x_d_out_w,y_d_out_w;

reg ctrl_in_reg, rst;

fft_opt_16_bram fft_16_a(clk,rst
,x_a_in,y_a_in,x_b_in,y_b_in,x_c_in,y_c_in,x_d_in,y_d_in
,x_a_out_w,y_a_out_w,x_b_out_w,y_b_out_w,x_c_out_w,y_c_out_w,x_d_out_w,y_d_out_w
,ctrl_in_reg,ctrl_out_wire
);

always@(posedge clk) begin
    x_a_in_reg <= x_a_in;
	y_a_in_reg <= y_a_in;
	x_b_in_reg <= x_b_in;
	y_b_in_reg <= y_b_in;
    x_c_in_reg <= x_c_in;
	y_c_in_reg <= y_c_in;
	x_d_in_reg <= x_d_in;
	y_d_in_reg <= y_d_in;
	////////////////////////////////////
	ctrl_in_reg <= ctrl_in;
	rst <= rst_in;
	ctrl_out <= ctrl_out_wire;
	
	x_a_out <=  x_a_out_w;
	y_a_out <=  y_a_out_w;
	x_b_out <=  x_b_out_w;
	y_b_out <=  y_b_out_w;
	x_c_out <=  x_c_out_w;
	y_c_out <=  y_c_out_w;
	x_d_out <=  x_d_out_w;
	y_d_out <=  y_d_out_w;
end

endmodule



module fft_opt_16_bram(
clk,
rst_in,
x_a_in,
y_a_in,
x_b_in,
y_b_in,
x_c_in,
y_c_in,
x_d_in,
y_d_in,
x_a_out,
y_a_out,
x_b_out,
y_b_out,
x_c_out,
y_c_out,
x_d_out,
y_d_out,
ctrl_in,
ctrl_out,
addr_0,
addr_1,
addr_2,
addr_3
);
localparam DATA_WIDTH = 8;
localparam PROBLEM_SIZE = 16;
localparam NUM_CHANNELS = 4;
localparam NUM_INPUTS = 2*NUM_CHANNELS;

input clk,rst_in,ctrl_in;	
//input[DATA_WIDTH-1:0]	data_in;
//output[DATA_WIDTH-1:0]	data_out;

/********************************************/
input[DATA_WIDTH-1:0] x_a_in,y_a_in,x_b_in,y_b_in
                     ,x_c_in,y_c_in,x_d_in,y_d_in;

output reg[DATA_WIDTH-1:0] x_a_out,y_a_out,x_b_out,y_b_out
                      ,x_c_out,y_c_out,x_d_out,y_d_out;
output reg ctrl_out;

output wire [1:0] addr_0;
output wire [1:0] addr_1;
output wire [1:0] addr_2;
output wire [1:0] addr_3;

reg[DATA_WIDTH-1:0] x_a_in_reg,y_a_in_reg,x_b_in_reg,y_b_in_reg
                     ,x_c_in_reg,y_c_in_reg,x_d_in_reg,y_d_in_reg;
//assign data_in = in[DATA_WIDTH-1:0];
//assign data_out = out[DATA_WIDTH-1:0];

reg ctrl_in_reg, rst;
always@(posedge clk) begin
    x_a_in_reg <= x_a_in;
	y_a_in_reg <= y_a_in;
	x_b_in_reg <= x_b_in;
	y_b_in_reg <= y_b_in;
    x_c_in_reg <= x_c_in;
	y_c_in_reg <= y_c_in;
	x_d_in_reg <= x_d_in;
	y_d_in_reg <= y_d_in;
	////////////////////////////////////
	ctrl_in_reg <= ctrl_in;
	rst <= rst_in;
end

/*******************************************/
/* STAGE 0 *********************************/
/*******************************************/

wire[DATA_WIDTH-1:0] pera_out[NUM_INPUTS-1:0];
wire ctrl_out_a;
pmt_upper_com #(DATA_WIDTH) per_a(clk,rst,x_a_in_reg,y_a_in_reg,x_b_in_reg,y_b_in_reg
															,x_c_in_reg,y_c_in_reg,x_d_in_reg,y_d_in_reg
												            ,pera_out[7],pera_out[6],pera_out[5],pera_out[4]
												            ,pera_out[3],pera_out[2],pera_out[1],pera_out[0]
															,ctrl_in_reg,ctrl_out_a);

wire[DATA_WIDTH-1:0] bufa_out[NUM_INPUTS-1:0];
wire ctrl_out_b[3:0];
//here better to change to littel endian
parameter START_PT_ADDR = {2'b00,2'b01,2'b10,2'b11};

data_fifo_blk #(0,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_a_a(clk,rst,{pera_out[7],pera_out[6]},{bufa_out[7],bufa_out[6]},ctrl_out_a,ctrl_out_b[3],addr_0);
data_fifo_blk #(1,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_a_b(clk,rst,{pera_out[5],pera_out[4]},{bufa_out[5],bufa_out[4]},ctrl_out_a,ctrl_out_b[2],addr_1);
data_fifo_blk #(2,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_a_c(clk,rst,{pera_out[3],pera_out[2]},{bufa_out[3],bufa_out[2]},ctrl_out_a,ctrl_out_b[1],addr_2);
data_fifo_blk #(3,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_a_d(clk,rst,{pera_out[1],pera_out[0]},{bufa_out[1],bufa_out[0]},ctrl_out_a,ctrl_out_b[0],addr_3);

wire[DATA_WIDTH-1:0] perb_out[NUM_INPUTS-1:0];
wire ctrl_out_c;
pmt_lower_com #(DATA_WIDTH) per_b(clk,rst,bufa_out[7],bufa_out[6],bufa_out[5],bufa_out[4]
					 ,bufa_out[3],bufa_out[2],bufa_out[1],bufa_out[0]
					 ,perb_out[7],perb_out[6],perb_out[5],perb_out[4]
					 ,perb_out[3],perb_out[2],perb_out[1],perb_out[0]
                     ,ctrl_out_b[0],ctrl_out_c);

// ================================================
wire[(DATA_WIDTH+2)-1:0] bflya_out[NUM_INPUTS-1:0];
wire ctrl_out_d;

btrfly_4 #(DATA_WIDTH) butterly_a(clk,rst,perb_out[7],perb_out[6],perb_out[5],perb_out[4]
																 ,perb_out[3],perb_out[2],perb_out[1],perb_out[0]
																 ,bflya_out[7],bflya_out[6],bflya_out[5],bflya_out[4]
																 ,bflya_out[3],bflya_out[2],bflya_out[1],bflya_out[0]
																 ,ctrl_out_c,ctrl_out_d
        );
wire[DATA_WIDTH-1:0] twda_out[NUM_INPUTS-1:0];
wire ctrl_out_e;

twiddle_mul #(DATA_WIDTH+2, DATA_WIDTH+1) 
twiddle_mul_4(clk,rst
						 ,bflya_out[7],bflya_out[6],bflya_out[5],bflya_out[4]
	           ,bflya_out[3],bflya_out[2],bflya_out[1],bflya_out[0]
	           ,twda_out[7],twda_out[6],twda_out[5],twda_out[4]
	           ,twda_out[3],twda_out[2],twda_out[1],twda_out[0]
						 ,ctrl_out_d,ctrl_out_e
);						 
	
/*******************************************/
/* STAGE 1 *********************************/
/*******************************************/
wire[DATA_WIDTH-1:0] perc_out[NUM_INPUTS-1:0];
wire ctrl_out_f;
pmt_upper_com #(DATA_WIDTH) 
per_c(clk,rst,twda_out[7],twda_out[6],twda_out[5],twda_out[4]
					 ,twda_out[3],twda_out[2],twda_out[1],twda_out[0]
					 ,perc_out[7],perc_out[6],perc_out[5],perc_out[4]
					 ,perc_out[3],perc_out[2],perc_out[1],perc_out[0]
                     ,ctrl_out_e,ctrl_out_f);					
					
wire[DATA_WIDTH-1:0] bufb_out[NUM_INPUTS-1:0];
wire ctrl_out_g[3:0];
//here better to change to littel endian

data_fifo_blk #(0,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_b_a(clk,rst,{perc_out[7],perc_out[6]},{bufb_out[7],bufb_out[6]},ctrl_out_f,ctrl_out_g[3]);
data_fifo_blk #(1,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_b_b(clk,rst,{perc_out[5],perc_out[4]},{bufb_out[5],bufb_out[4]},ctrl_out_f,ctrl_out_g[2]);
data_fifo_blk #(2,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_b_c(clk,rst,{perc_out[3],perc_out[2]},{bufb_out[3],bufb_out[2]},ctrl_out_f,ctrl_out_g[1]);
data_fifo_blk #(3,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_b_d(clk,rst,{perc_out[1],perc_out[0]},{bufb_out[1],bufb_out[0]},ctrl_out_f,ctrl_out_g[0]);

wire[DATA_WIDTH-1:0] perd_out[NUM_INPUTS-1:0];
wire ctrl_out_h;
pmt_lower_com #(DATA_WIDTH) 
per_d(clk,rst,bufb_out[7],bufb_out[6],bufb_out[5],bufb_out[4]
					 ,bufb_out[3],bufb_out[2],bufb_out[1],bufb_out[0]
					 ,perd_out[7],perd_out[6],perd_out[5],perd_out[4]
					 ,perd_out[3],perd_out[2],perd_out[1],perd_out[0]
                     ,ctrl_out_g[0],ctrl_out_h);	

// ================================================
wire[(DATA_WIDTH+2)-1:0] bflyb_out[NUM_INPUTS-1:0];
wire ctrl_out_i;

btrfly_4 #(DATA_WIDTH)  butterly_b(clk,rst,perd_out[7],perd_out[6],perd_out[5],perd_out[4]
					 ,perd_out[3],perd_out[2],perd_out[1],perd_out[0]
                     ,bflyb_out[7],bflyb_out[6],bflyb_out[5],bflyb_out[4]
					 ,bflyb_out[3],bflyb_out[2],bflyb_out[1],bflyb_out[0]
                     ,ctrl_out_h,ctrl_out_i
        );

/*******************************************/
/* STAGE 2 *********************************/
/*******************************************/
					
wire[DATA_WIDTH-1:0] pere_out[NUM_INPUTS-1:0];
wire ctrl_out_j;
pmt_upper_com #(DATA_WIDTH)  
per_e(clk,rst,bflyb_out[7][DATA_WIDTH-1:0],bflyb_out[6][DATA_WIDTH-1:0],bflyb_out[5][DATA_WIDTH-1:0],bflyb_out[4][DATA_WIDTH-1:0]
					 ,bflyb_out[3][DATA_WIDTH-1:0],bflyb_out[2][DATA_WIDTH-1:0],bflyb_out[1][DATA_WIDTH-1:0],bflyb_out[0][DATA_WIDTH-1:0]
					 ,pere_out[7],pere_out[6],pere_out[5],pere_out[4]
					 ,pere_out[3],pere_out[2],pere_out[1],pere_out[0]
                     ,ctrl_out_i,ctrl_out_j);	

wire[DATA_WIDTH-1:0] bufc_out[NUM_INPUTS-1:0];
wire ctrl_out_k[3:0];
//here better to change to littel endian

data_fifo_blk #(0,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_c_a(clk,rst,{pere_out[7],pere_out[6]},{bufc_out[7],bufc_out[6]},ctrl_out_j,ctrl_out_k[3]);
data_fifo_blk #(1,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_c_b(clk,rst,{pere_out[5],pere_out[4]},{bufc_out[5],bufc_out[4]},ctrl_out_j,ctrl_out_k[2]);
data_fifo_blk #(2,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_c_c(clk,rst,{pere_out[3],pere_out[2]},{bufc_out[3],bufc_out[2]},ctrl_out_j,ctrl_out_k[1]);
data_fifo_blk #(3,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_c_d(clk,rst,{pere_out[1],pere_out[0]},{bufc_out[1],bufc_out[0]},ctrl_out_j,ctrl_out_k[0]);

wire[DATA_WIDTH-1:0] perf_out[NUM_INPUTS-1:0];
wire ctrl_out_l;
pmt_lower_com #(DATA_WIDTH) 
per_f(clk,rst,bufc_out[7],bufc_out[6],bufc_out[5],bufc_out[4]
		 ,bufc_out[3],bufc_out[2],bufc_out[1],bufc_out[0]
		 ,perf_out[7],perf_out[6],perf_out[5],perf_out[4]
		 ,perf_out[3],perf_out[2],perf_out[1],perf_out[0]
		 ,ctrl_out_k[0],ctrl_out_l);	
					
					
always@(posedge clk)
begin
  //data_out <= perf_out;
  x_a_out <= perf_out[7];
  y_a_out <= perf_out[6];
  x_b_out <= perf_out[5];
  y_b_out <= perf_out[4];
  x_c_out <= perf_out[3];
  y_c_out <= perf_out[2];
  x_d_out <= perf_out[1];
  y_d_out <= perf_out[0];
  ctrl_out <= ctrl_out_l;
end

endmodule





module fft_opt_16_sram(
clk,
rst_in,
x_a_in,
y_a_in,
x_b_in,
y_b_in,
x_c_in,
y_c_in,
x_d_in,
y_d_in,
x_a_out,
y_a_out,
x_b_out,
y_b_out,
x_c_out,
y_c_out,
x_d_out,
y_d_out,
ctrl_in,
ctrl_out
);
localparam DATA_WIDTH = 8;
localparam PROBLEM_SIZE = 16;
localparam NUM_CHANNELS = 4;
localparam NUM_INPUTS = 2*NUM_CHANNELS;

input clk,rst_in,ctrl_in;	
//input[DATA_WIDTH-1:0]	data_in;
//output[DATA_WIDTH-1:0]	data_out;

/********************************************/
input[DATA_WIDTH-1:0] x_a_in,y_a_in,x_b_in,y_b_in
                     ,x_c_in,y_c_in,x_d_in,y_d_in;

output reg[DATA_WIDTH-1:0] x_a_out,y_a_out,x_b_out,y_b_out
                      ,x_c_out,y_c_out,x_d_out,y_d_out;
output reg ctrl_out;

reg[DATA_WIDTH-1:0] x_a_in_reg,y_a_in_reg,x_b_in_reg,y_b_in_reg
                     ,x_c_in_reg,y_c_in_reg,x_d_in_reg,y_d_in_reg;
//assign data_in = in[DATA_WIDTH-1:0];
//assign data_out = out[DATA_WIDTH-1:0];

reg ctrl_in_reg, rst;
always@(posedge clk) begin
    x_a_in_reg <= x_a_in;
	y_a_in_reg <= y_a_in;
	x_b_in_reg <= x_b_in;
	y_b_in_reg <= y_b_in;
    x_c_in_reg <= x_c_in;
	y_c_in_reg <= y_c_in;
	x_d_in_reg <= x_d_in;
	y_d_in_reg <= y_d_in;
	////////////////////////////////////
	ctrl_in_reg <= ctrl_in;
	rst <= rst_in;
end

/*******************************************/
wire[DATA_WIDTH-1:0] pera_out[NUM_INPUTS-1:0];
wire ctrl_out_a;
pmt_upper_com #(DATA_WIDTH) per_a(clk,rst,x_a_in_reg,y_a_in_reg,x_b_in_reg,y_b_in_reg
																	  ,x_c_in_reg,y_c_in_reg,x_d_in_reg,y_d_in_reg
												            ,pera_out[7],pera_out[6],pera_out[5],pera_out[4]
												            ,pera_out[3],pera_out[2],pera_out[1],pera_out[0]
																	  ,ctrl_in_reg,ctrl_out_a);

/*******************************************/
wire[DATA_WIDTH-1:0] bufa_out[NUM_INPUTS-1:0];
wire ctrl_out_b[3:0];
//here better to change to littel endian
parameter START_PT_ADDR = {2'b00,2'b01,2'b10,2'b11};

data_fifo_distRAM #(0,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_a_a(clk,rst,{pera_out[7],pera_out[6]},{bufa_out[7],bufa_out[6]},ctrl_out_a,ctrl_out_b[3]);
data_fifo_distRAM #(1,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_a_b(clk,rst,{pera_out[5],pera_out[4]},{bufa_out[5],bufa_out[4]},ctrl_out_a,ctrl_out_b[2]);
data_fifo_distRAM #(2,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_a_c(clk,rst,{pera_out[3],pera_out[2]},{bufa_out[3],bufa_out[2]},ctrl_out_a,ctrl_out_b[1]);
data_fifo_distRAM #(3,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_a_d(clk,rst,{pera_out[1],pera_out[0]},{bufa_out[1],bufa_out[0]},ctrl_out_a,ctrl_out_b[0]);

/*******************************************/
wire[DATA_WIDTH-1:0] perb_out[NUM_INPUTS-1:0];
wire ctrl_out_c;
pmt_lower_com #(DATA_WIDTH) per_b(clk,rst,bufa_out[7],bufa_out[6],bufa_out[5],bufa_out[4]
					 ,bufa_out[3],bufa_out[2],bufa_out[1],bufa_out[0]
					 ,perb_out[7],perb_out[6],perb_out[5],perb_out[4]
					 ,perb_out[3],perb_out[2],perb_out[1],perb_out[0]
                     ,ctrl_out_b[0],ctrl_out_c);

/*******************************************/
wire[(DATA_WIDTH+2)-1:0] bflya_out[NUM_INPUTS-1:0];
wire ctrl_out_d;

btrfly_4 #(DATA_WIDTH) butterly_a(clk,rst,perb_out[7],perb_out[6],perb_out[5],perb_out[4]
																 ,perb_out[3],perb_out[2],perb_out[1],perb_out[0]
																 ,bflya_out[7],bflya_out[6],bflya_out[5],bflya_out[4]
																 ,bflya_out[3],bflya_out[2],bflya_out[1],bflya_out[0]
																 ,ctrl_out_c,ctrl_out_d
        );
/*******************************************/	 
wire[DATA_WIDTH-1:0] twda_out[NUM_INPUTS-1:0];
wire ctrl_out_e;

twiddle_mul #(DATA_WIDTH+2, DATA_WIDTH+1) 
twiddle_mul_4(clk,rst
						 ,bflya_out[7],bflya_out[6],bflya_out[5],bflya_out[4]
	           ,bflya_out[3],bflya_out[2],bflya_out[1],bflya_out[0]
	           ,twda_out[7],twda_out[6],twda_out[5],twda_out[4]
	           ,twda_out[3],twda_out[2],twda_out[1],twda_out[0]
						 ,ctrl_out_d,ctrl_out_e
);						 
	
/*******************************************/
wire[DATA_WIDTH-1:0] perc_out[NUM_INPUTS-1:0];
wire ctrl_out_f;
pmt_upper_com #(DATA_WIDTH) 
per_c(clk,rst,twda_out[7],twda_out[6],twda_out[5],twda_out[4]
					 ,twda_out[3],twda_out[2],twda_out[1],twda_out[0]
					 ,perc_out[7],perc_out[6],perc_out[5],perc_out[4]
					 ,perc_out[3],perc_out[2],perc_out[1],perc_out[0]
                     ,ctrl_out_e,ctrl_out_f);					
					
/*******************************************/
wire[DATA_WIDTH-1:0] bufb_out[NUM_INPUTS-1:0];
wire ctrl_out_g[3:0];
//here better to change to littel endian

data_fifo_distRAM #(0,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_b_a(clk,rst,{perc_out[7],perc_out[6]},{bufb_out[7],bufb_out[6]},ctrl_out_f,ctrl_out_g[3]);
data_fifo_distRAM #(1,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_b_b(clk,rst,{perc_out[5],perc_out[4]},{bufb_out[5],bufb_out[4]},ctrl_out_f,ctrl_out_g[2]);
data_fifo_distRAM #(2,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_b_c(clk,rst,{perc_out[3],perc_out[2]},{bufb_out[3],bufb_out[2]},ctrl_out_f,ctrl_out_g[1]);
data_fifo_distRAM #(3,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_b_d(clk,rst,{perc_out[1],perc_out[0]},{bufb_out[1],bufb_out[0]},ctrl_out_f,ctrl_out_g[0]);

/*******************************************/
wire[DATA_WIDTH-1:0] perd_out[NUM_INPUTS-1:0];
wire ctrl_out_h;
pmt_lower_com #(DATA_WIDTH) 
per_d(clk,rst,bufb_out[7],bufb_out[6],bufb_out[5],bufb_out[4]
					 ,bufb_out[3],bufb_out[2],bufb_out[1],bufb_out[0]
					 ,perd_out[7],perd_out[6],perd_out[5],perd_out[4]
					 ,perd_out[3],perd_out[2],perd_out[1],perd_out[0]
                     ,ctrl_out_g[0],ctrl_out_h);	

/*******************************************/
wire[(DATA_WIDTH+2)-1:0] bflyb_out[NUM_INPUTS-1:0];
wire ctrl_out_i;

btrfly_4 #(DATA_WIDTH)  butterly_b(clk,rst,perd_out[7],perd_out[6],perd_out[5],perd_out[4]
					 ,perd_out[3],perd_out[2],perd_out[1],perd_out[0]
                     ,bflyb_out[7],bflyb_out[6],bflyb_out[5],bflyb_out[4]
					 ,bflyb_out[3],bflyb_out[2],bflyb_out[1],bflyb_out[0]
                     ,ctrl_out_h,ctrl_out_i
        );

/*******************************************/
					
wire[DATA_WIDTH-1:0] pere_out[NUM_INPUTS-1:0];
wire ctrl_out_j;
pmt_upper_com #(DATA_WIDTH)  
per_e(clk,rst,bflyb_out[7][DATA_WIDTH-1:0],bflyb_out[6][DATA_WIDTH-1:0],bflyb_out[5][DATA_WIDTH-1:0],bflyb_out[4][DATA_WIDTH-1:0]
					 ,bflyb_out[3][DATA_WIDTH-1:0],bflyb_out[2][DATA_WIDTH-1:0],bflyb_out[1][DATA_WIDTH-1:0],bflyb_out[0][DATA_WIDTH-1:0]
					 ,pere_out[7],pere_out[6],pere_out[5],pere_out[4]
					 ,pere_out[3],pere_out[2],pere_out[1],pere_out[0]
                     ,ctrl_out_i,ctrl_out_j);	

/*******************************************/
wire[DATA_WIDTH-1:0] bufc_out[NUM_INPUTS-1:0];
wire ctrl_out_k[3:0];
//here better to change to littel endian

data_fifo_distRAM #(0,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_c_a(clk,rst,{pere_out[7],pere_out[6]},{bufc_out[7],bufc_out[6]},ctrl_out_j,ctrl_out_k[3]);
data_fifo_distRAM #(1,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_c_b(clk,rst,{pere_out[5],pere_out[4]},{bufc_out[5],bufc_out[4]},ctrl_out_j,ctrl_out_k[2]);
data_fifo_distRAM #(2,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_c_c(clk,rst,{pere_out[3],pere_out[2]},{bufc_out[3],bufc_out[2]},ctrl_out_j,ctrl_out_k[1]);
data_fifo_distRAM #(3,2*DATA_WIDTH,PROBLEM_SIZE/8) fifo_c_d(clk,rst,{pere_out[1],pere_out[0]},{bufc_out[1],bufc_out[0]},ctrl_out_j,ctrl_out_k[0]);

/*******************************************/
wire[DATA_WIDTH-1:0] perf_out[NUM_INPUTS-1:0];
wire ctrl_out_l;
pmt_lower_com #(DATA_WIDTH) 
per_f(clk,rst,bufc_out[7],bufc_out[6],bufc_out[5],bufc_out[4]
		 ,bufc_out[3],bufc_out[2],bufc_out[1],bufc_out[0]
		 ,perf_out[7],perf_out[6],perf_out[5],perf_out[4]
		 ,perf_out[3],perf_out[2],perf_out[1],perf_out[0]
		 ,ctrl_out_k[0],ctrl_out_l);	
					
					
always@(posedge clk)
begin
  //data_out <= perf_out;
  x_a_out <= perf_out[7];
  y_a_out <= perf_out[6];
  x_b_out <= perf_out[5];
  y_b_out <= perf_out[4];
  x_c_out <= perf_out[3];
  y_c_out <= perf_out[2];
  x_d_out <= perf_out[1];
  y_d_out <= perf_out[0];
  ctrl_out <= ctrl_out_l;
end

endmodule
