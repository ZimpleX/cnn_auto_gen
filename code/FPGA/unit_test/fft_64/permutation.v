`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  
// Engineer:       Ren Chen
// 
// Create Date:    21:53:31 02/26/2013 
// Design Name:    
// Module Name:    permutation 
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

module mux_n(
sel,
data_in,
data_out
);
parameter ADDR = 2;
parameter IN_WIDTH = 1<<ADDR;
input[ADDR-1:0] sel;
input[IN_WIDTH-1:0] data_in;
output data_out;

wire[ADDR-1:0] sel;
wire[IN_WIDTH-1:0] data_in;
wire data_out;
assign data_out = data_in[sel];

endmodule

module mux_n_reg(
clk,
rst,
sel,
data_in,
data_out
);
parameter ADDR = 2;
parameter IN_WIDTH = 1<<ADDR;

input clk,rst;
input[ADDR-1:0] sel;
input[IN_WIDTH-1:0] data_in;
output reg data_out;

wire[ADDR-1:0] sel;
wire[IN_WIDTH-1:0] data_in;

always@(posedge clk)
begin
  if(rst) begin
    data_out <= 1'b0;
  end else
    data_out <= data_in[sel];
end
endmodule


module pmt_upper_com(
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
parameter DATA_WIDTH = 16;
parameter WIDTH_COUNTER = 2;                 
//N=16,64,256, 1,2,4 respectively need modification manually, need log2n function for //automatically generation
//localparam NUM_CHANNELS= 4;   //OPTION: 2,4,8,16
//localparam NUM_INPUTS = 2*NUM_CHANNELS;
parameter FLAG_COUNTER = 1;                  //need modification manually, =0 if N=16;

parameter PROBLEM_SIZE = 64;
parameter PER_DISTANCE = PROBLEM_SIZE/16;   //update "sel" every PER_DISTANCE cycles;

input clk,rst,ctrl_in;
input[DATA_WIDTH-1:0] x_a_in,y_a_in,x_b_in,y_b_in
                     ,x_c_in,y_c_in,x_d_in,y_d_in;

output[DATA_WIDTH-1:0] x_a_out,y_a_out,x_b_out,y_b_out
                      ,x_c_out,y_c_out,x_d_out,y_d_out;
output ctrl_out;

//for 8 16x 4-1 mux
reg[1:0] sel;
reg proc_start;    //to tag the fft compuation starts
reg[WIDTH_COUNTER-1:0] counter;  //used for counting cycles;
reg flag_counter;  //when N=16, counnter is not used;
wire[1:0]  address_update;

//reg start_update;
wire[3:0] mux_in[7:0][DATA_WIDTH-1:0];
wire[DATA_WIDTH-1:0] mux_out[7:0];

genvar i,j;
generate
for(i=0;i<DATA_WIDTH;i=i+1) begin:MUX_PER
	assign mux_in[7][i] = {x_c_in[i],x_b_in[i],x_d_in[i],x_a_in[i]};
	assign mux_in[6][i] = {y_c_in[i],y_b_in[i],y_d_in[i],y_a_in[i]};
	assign mux_in[5][i] = {x_d_in[i],x_c_in[i],x_a_in[i],x_b_in[i]};
	assign mux_in[4][i] = {y_d_in[i],y_c_in[i],y_a_in[i],y_b_in[i]};
	assign mux_in[3][i] = {x_a_in[i],x_d_in[i],x_b_in[i],x_c_in[i]};
	assign mux_in[2][i] = {y_a_in[i],y_d_in[i],y_b_in[i],y_c_in[i]};
	assign mux_in[1][i] = {x_b_in[i],x_a_in[i],x_c_in[i],x_d_in[i]};
	assign mux_in[0][i] = {y_b_in[i],y_a_in[i],y_c_in[i],y_d_in[i]};
	end
endgenerate

generate
for(j=0;j<8;j=j+1) begin:MUX_OUT
  for(i=0;i<DATA_WIDTH;i=i+1) begin:MUX_BIT
  	  mux_n MUXUU(sel,mux_in[j][i],mux_out[j][i]);
	end
  end
endgenerate

assign address_update = (((flag_counter)&&(counter!=((1<<WIDTH_COUNTER)-1))) ?sel :({sel[0],!sel[1]}));
//state for generate select
always@(posedge clk)  //should be careful!!! 
//try posedge or negedge, when using postitive,data have to be registered
begin
  if(rst) begin
		sel <= 2'b00;
		proc_start <= 1'b0;
		counter <= 0;
		flag_counter <= FLAG_COUNTER;   //need modification manually if N = 16;
		//data_out <= 0;
	end else begin
	  if(ctrl_in) begin
        proc_start <= 1'b1;	   //ctrl_in is a wire, do not use ?: here
		counter <= 0;
	  end else begin
	    counter <= counter + 1;
	  end
	  //some problems may happen here, but this saves logics
	  sel <= (proc_start==1'b0)?(2'b00):(address_update);       
	end	
end

wire[DATA_WIDTH-1:0] wire_out[7:0];
generate
for(i=0;i<8;i=i+1) begin:WIRE_OUT_PER
  assign wire_out[i] = mux_out[i];
  /*assign wire_out[i] = {mux_out[i][15],mux_out[i][14],mux_out[i][13],mux_out[i][12]
											 ,mux_out[i][11],mux_out[i][10],mux_out[i][9],mux_out[i][8]
											 ,mux_out[i][7],mux_out[i][6],mux_out[i][5],mux_out[i][4]
											 ,mux_out[i][3],mux_out[i][2],mux_out[i][1],mux_out[i][0]};*/
end
endgenerate
			
assign	x_a_out = wire_out[7];
assign	y_a_out = wire_out[6];
assign	x_b_out = wire_out[5];
assign	y_b_out = wire_out[4];
assign	x_c_out = wire_out[3];
assign	y_c_out = wire_out[2];
assign	x_d_out = wire_out[1];
assign	y_d_out = wire_out[0];							  
assign	ctrl_out = ctrl_in;

endmodule


module pmt_lower_com(
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
parameter DATA_WIDTH = 16;
parameter WIDTH_COUNTER = 2;                
 //N=16,64,256, 1,2,4 respectively need modification manually, need log2n function for //automatically generation

//localparam NUM_CHANNELS= 4;   //OPTION: 2,4,8,16
//localparam NUM_INPUTS = 2*NUM_CHANNELS;
parameter FLAG_COUNTER = 1;                  //need modification manually, =0 if N=16;

parameter PROBLEM_SIZE = 64;
parameter PER_DISTANCE = PROBLEM_SIZE/16;   //update "sel" every PER_DISTANCE cycles;

input clk,rst,ctrl_in;
input[DATA_WIDTH-1:0] x_a_in,y_a_in,x_b_in,y_b_in
                     ,x_c_in,y_c_in,x_d_in,y_d_in;

output[DATA_WIDTH-1:0] x_a_out,y_a_out,x_b_out,y_b_out
                      ,x_c_out,y_c_out,x_d_out,y_d_out;
output ctrl_out;

//for 8 16x 4-1 mux
reg[1:0] sel;
reg proc_start;    //to tag the fft compuation starts
reg[WIDTH_COUNTER-1:0] counter;  //used for counting cycles;
reg flag_counter;  //when N=16, counnter is not used;
wire[1:0]  address_update;

//reg start_update;
wire[3:0] mux_in[7:0][DATA_WIDTH-1:0];
wire[DATA_WIDTH-1:0] mux_out[7:0];

genvar i,j;
generate
for(i=0;i<DATA_WIDTH;i=i+1) begin:MUX_PER
	assign mux_in[7][i] = {x_c_in[i],x_d_in[i],x_b_in[i],x_a_in[i]};
	assign mux_in[6][i] = {y_c_in[i],y_d_in[i],y_b_in[i],y_a_in[i]};
	assign mux_in[5][i] = {x_d_in[i],x_a_in[i],x_c_in[i],x_b_in[i]};
	assign mux_in[4][i] = {y_d_in[i],y_a_in[i],y_c_in[i],y_b_in[i]};
	assign mux_in[3][i] = {x_a_in[i],x_b_in[i],x_d_in[i],x_c_in[i]};
	assign mux_in[2][i] = {y_a_in[i],y_b_in[i],y_d_in[i],y_c_in[i]};
	assign mux_in[1][i] = {x_b_in[i],x_c_in[i],x_a_in[i],x_d_in[i]};
	assign mux_in[0][i] = {y_b_in[i],y_c_in[i],y_a_in[i],y_d_in[i]};
	end
endgenerate

generate
for(j=0;j<8;j=j+1) begin:MUX_OUT
  for(i=0;i<DATA_WIDTH;i=i+1) begin:MUX_BIT
  	  mux_n MUXUU(sel,mux_in[j][i],mux_out[j][i]);
	end
  end
endgenerate

assign address_update = (((flag_counter)&&(counter!=((1<<WIDTH_COUNTER)-1))) ?sel :({sel[0],!sel[1]}));
//state for generate select
always@(posedge clk)  //should be careful!!! 
//try posedge or negedge, when using postitive,data have to be registered
begin
  if(rst) begin
		sel <= 2'b00;
		proc_start <= 1'b0;
		counter <= 0;
		flag_counter <= FLAG_COUNTER;   //need modification manually if N = 16;
		//data_out <= 0;
	end else begin
	   if(ctrl_in) begin
         proc_start <= 1'b1;	   //ctrl_in is a wire, do not use ?: here
		 counter <= 0;
	   end else begin
	     counter <= counter + 1;
	   end
	  //some problems may happen here, but this saves logics
	  sel <= (proc_start==1'b0)?(2'b00): address_update; 			
	end	
end

wire[DATA_WIDTH-1:0] wire_out[7:0];
generate
for(i=0;i<8;i=i+1) begin:WIRE_OUT_PER
  assign wire_out[i] = mux_out[i];
  /*assign wire_out[i] = {mux_out[i][15],mux_out[i][14],mux_out[i][13],mux_out[i][12]
											 ,mux_out[i][11],mux_out[i][10],mux_out[i][9],mux_out[i][8]
											 ,mux_out[i][7],mux_out[i][6],mux_out[i][5],mux_out[i][4]
											 ,mux_out[i][3],mux_out[i][2],mux_out[i][1],mux_out[i][0]};*/
end
endgenerate
			
assign	x_a_out = wire_out[7];
assign	y_a_out = wire_out[6];
assign	x_b_out = wire_out[5];
assign	y_b_out = wire_out[4];
assign	x_c_out = wire_out[3];
assign	y_c_out = wire_out[2];
assign	x_d_out = wire_out[1];
assign	y_d_out = wire_out[0];							  
assign	ctrl_out = ctrl_in;

endmodule




