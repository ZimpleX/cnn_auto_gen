`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:51:39 02/26/2013 
// Design Name: 
// Module Name:    butterfly 
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

module btrfly_4(
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
parameter DATA_WIDTH = 16;
parameter SIZE_BLOCK = 4;
parameter NUM_INPUT = 2*SIZE_BLOCK; //including real part and img part

input clk,rst,ctrl_in;
input[DATA_WIDTH-1:0] x_a_in,y_a_in
                     ,x_b_in,y_b_in
                     ,x_c_in,y_c_in
					 ,x_d_in,y_d_in;
output ctrl_out;
output reg[DATA_WIDTH+1:0] xx_a_out,yy_a_out
                      ,xx_b_out,yy_b_out
                      ,xx_c_out,yy_c_out
					  ,xx_d_out,yy_d_out;

/**************************calculate immediate****************************/
//xa' = xa+xb+xc+xd = xa_temp
//ya' = ya+yb+yc+yd = ya_temp
//xb' = (xa+yb-xc-yd)Cb - (ya-xb-yc+xd)(-Sb) = xb_temp*Cb - yb_temp*(-Sb)
//yb' = (ya-xb-yc+xd)Cb + (xa+yb-xc-yd)(-Sb) = yb_temp*Cb + xb_temp*(-Sb)
//xc' = (xa-xb+xc-xd)Cc - (ya-yb+yc-yd)(-Sc) = xc_temp*Cc - yc_temp*(-Sc)
//yc' = (ya-yb+yc-yd)Cc + (xa-xb+xc-xd)(-Sc) = yc_temp*Cc + xc_temp*(-Sc)
//xd' = (xa-yb-xc+yd)Cd - (ya+xb-yc-xd)(-Sd) = xd_temp*Cd - yd_temp*(-Sd)
//yd' = (ya+xb-yc-xd)Cd + (xa-yb-xc+yd)(-Sd) = yd_temp*Cd + xd_temp*(-Sd)
reg[DATA_WIDTH:0]  xapc,xamc,xbpd,xbmd;
wire[DATA_WIDTH:0] xapc_w,xamc_w,xbpd_w,xbmd_w;
reg[DATA_WIDTH:0]  yapc,yamc,ybpd,ybmd;
wire[DATA_WIDTH:0] yapc_w,yamc_w,ybpd_w,ybmd_w;
reg ctrl_in_tmp, ctrl_in_sa;  //stage
reg[DATA_WIDTH-1:0] x_a_in_r,y_a_in_r
                     ,x_b_in_r,y_b_in_r
                     ,x_c_in_r,y_c_in_r
					 ,x_d_in_r,y_d_in_r;

adder #(DATA_WIDTH,DATA_WIDTH,DATA_WIDTH+1) xa_add_xc(1'b0,x_a_in_r,x_c_in_r,xapc_w);
adder #(DATA_WIDTH,DATA_WIDTH,DATA_WIDTH+1) xa_sub_xc(1'b1,x_a_in_r,x_c_in_r,xamc_w);
adder #(DATA_WIDTH,DATA_WIDTH,DATA_WIDTH+1) xb_add_xd(1'b0,x_b_in_r,x_d_in_r,xbpd_w);
adder #(DATA_WIDTH,DATA_WIDTH,DATA_WIDTH+1) xb_sub_xd(1'b1,x_b_in_r,x_d_in_r,xbmd_w);
adder #(DATA_WIDTH,DATA_WIDTH,DATA_WIDTH+1) ya_add_yc(1'b0,y_a_in_r,y_c_in_r,yapc_w);
adder #(DATA_WIDTH,DATA_WIDTH,DATA_WIDTH+1) ya_sub_yc(1'b1,y_a_in_r,y_c_in_r,yamc_w);
adder #(DATA_WIDTH,DATA_WIDTH,DATA_WIDTH+1) yb_add_yd(1'b0,y_b_in_r,y_d_in_r,ybpd_w);
adder #(DATA_WIDTH,DATA_WIDTH,DATA_WIDTH+1) yb_sub_yd(1'b1,y_b_in_r,y_d_in_r,ybmd_w);

always@(posedge clk)
begin
  xapc <= xapc_w;
  xamc <= xamc_w;
  xbpd <= xbpd_w;
  xbmd <= xbmd_w;
  yapc <= yapc_w;
  yamc <= yamc_w;
  ybpd <= ybpd_w;
  ybmd <= ybmd_w; 
  x_a_in_r <=  x_a_in;
  y_a_in_r <=  y_a_in;
  x_b_in_r <=  x_b_in;
  y_b_in_r <=  y_b_in;
  x_c_in_r <=  x_c_in;
  y_c_in_r <=  y_c_in;
  x_d_in_r <=  x_d_in;
  y_d_in_r <=  y_d_in;
  ctrl_in_tmp <= ctrl_in;
  ctrl_in_sa <= ctrl_in_tmp;  //be careful with this signal;
end

/*******************************************************************************/
wire[DATA_WIDTH+1:0] xxa_temp,xxb_temp,xxc_temp,xxd_temp;
wire[DATA_WIDTH+1:0] yya_temp,yyb_temp,yyc_temp,yyd_temp;
reg ctrl_in_sb;

adder #(DATA_WIDTH+1,DATA_WIDTH+1,DATA_WIDTH+2) xapc_add_xbpd(1'b0,xapc,xbpd,xxa_temp);
adder #(DATA_WIDTH+1,DATA_WIDTH+1,DATA_WIDTH+2) yapc_add_ybpd(1'b0,yapc,ybpd,yya_temp);
adder #(DATA_WIDTH+1,DATA_WIDTH+1,DATA_WIDTH+2) xamc_add_ybmd(1'b0,xamc,ybmd,xxb_temp);
adder #(DATA_WIDTH+1,DATA_WIDTH+1,DATA_WIDTH+2) yamc_sub_xbmd(1'b1,yamc,xbmd,yyb_temp);
adder #(DATA_WIDTH+1,DATA_WIDTH+1,DATA_WIDTH+2) xapc_sub_xbpd(1'b1,xapc,xbpd,xxc_temp);
adder #(DATA_WIDTH+1,DATA_WIDTH+1,DATA_WIDTH+2) yapc_sub_ybpd(1'b1,yapc,ybpd,yyc_temp);
adder #(DATA_WIDTH+1,DATA_WIDTH+1,DATA_WIDTH+2) xamc_sub_ybmd(1'b1,xamc,ybmd,xxd_temp);
adder #(DATA_WIDTH+1,DATA_WIDTH+1,DATA_WIDTH+2) yamc_add_xbmd(1'b0,yamc,xbmd,yyd_temp);
                                                                        
always@(posedge clk)
begin
  xx_a_out <= xxa_temp;
  yy_a_out <= yya_temp;
  xx_b_out <= xxb_temp;
  yy_b_out <= yyb_temp;
  xx_c_out <= xxc_temp;
  yy_c_out <= yyc_temp;
  xx_d_out <= xxd_temp;
  yy_d_out <= yyd_temp;
  ctrl_in_sb <= ctrl_in_sa;
end

assign ctrl_out = ctrl_in_sb;

endmodule





module butterfly_4(
clk,
data_in,
data_out,
ctrl_in,
ctrl_out
        );
parameter DATA_WIDTH = 16;
parameter SIZE_BLOCK = 4;
parameter NUM_INPUT = 2*SIZE_BLOCK; //including real part and img part

input clk,ctrl_in;
input[(DATA_WIDTH*NUM_INPUT-1):0] data_in;            //xa; ya; xb; yb; xc; yc; xd; yd;  xa:MSB
output[(DATA_WIDTH+2)*NUM_INPUT-1:0] data_out;       //width extension
output ctrl_out;

/*****************to reduce input/output ports to bind********************/
wire [DATA_WIDTH-1:0]  wire_in[NUM_INPUT-1:0];   //xa; ya; xb; yb; xc; yc; xd; yd;

genvar i;
generate
for(i=0;i<NUM_INPUT;i=i+1) begin:WIRE_IN
  assign wire_in[i] = data_in[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i];
end
endgenerate

/**************************calculate immediate****************************/
//xa' = xa+xb+xc+xd = xa_temp
//ya' = ya+yb+yc+yd = ya_temp
//xb' = (xa+yb每xc-yd)Cb - (ya每xb每yc+xd)(-Sb) = xb_temp*Cb - yb_temp*(-Sb)
//yb' = (ya每xb每yc+xd)Cb + (xa+yb每xc-yd)(-Sb) = yb_temp*Cb + xb_temp*(-Sb)
//xc' = (xa每xb+xc-xd)Cc - (ya每yb+yc-yd)(-Sc) = xc_temp*Cc - yc_temp*(-Sc)
//yc' = (ya每yb+yc-yd)Cc + (xa每xb+xc-xd)(-Sc) = yc_temp*Cc + xc_temp*(-Sc)
//xd' = (xa每yb每xc+yd)Cd - (ya+xb每yc-xd)(-Sd) = xd_temp*Cd - yd_temp*(-Sd)
//yd' = (ya+xb每yc-xd)Cd + (xa每yb每xc+yd)(-Sd) = yd_temp*Cd + xd_temp*(-Sd)
reg[DATA_WIDTH+1:0] xapc;
reg[DATA_WIDTH+1:0] xamc;
reg[DATA_WIDTH+1:0] xbpd;
reg[DATA_WIDTH+1:0] xbmd;
reg[DATA_WIDTH+1:0] yapc;
reg[DATA_WIDTH+1:0] yamc;
reg[DATA_WIDTH+1:0] ybpd;
reg[DATA_WIDTH+1:0] ybmd;
reg ctrl_in_s1;  //stage

always@(posedge clk)
begin
  xapc <= {{2{wire_in[7][DATA_WIDTH-1]}},wire_in[7]} + {{2{wire_in[3][DATA_WIDTH-1]}},wire_in[3]};
  xamc <= {{2{wire_in[7][DATA_WIDTH-1]}},wire_in[7]} - {{2{wire_in[3][DATA_WIDTH-1]}},wire_in[3]};
  xbpd <= {{2{wire_in[5][DATA_WIDTH-1]}},wire_in[5]} + {{2{wire_in[1][DATA_WIDTH-1]}},wire_in[1]};
  xbmd <= {{2{wire_in[5][DATA_WIDTH-1]}},wire_in[5]} - {{2{wire_in[1][DATA_WIDTH-1]}},wire_in[1]};
  yapc <= {{2{wire_in[6][DATA_WIDTH-1]}},wire_in[6]} + {{2{wire_in[2][DATA_WIDTH-1]}},wire_in[2]};
  yamc <= {{2{wire_in[6][DATA_WIDTH-1]}},wire_in[6]} - {{2{wire_in[2][DATA_WIDTH-1]}},wire_in[2]};
  ybpd <= {{2{wire_in[4][DATA_WIDTH-1]}},wire_in[4]} + {{2{wire_in[0][DATA_WIDTH-1]}},wire_in[0]};
  ybmd <= {{2{wire_in[4][DATA_WIDTH-1]}},wire_in[4]} - {{2{wire_in[0][DATA_WIDTH-1]}},wire_in[0]}; 
	ctrl_in_s1 <= ctrl_in;
end

/*******************************************************************************/
reg[DATA_WIDTH+1:0] xa_temp;   //sign extension has been done above with two more bits
reg[DATA_WIDTH+1:0] ya_temp;
reg[DATA_WIDTH+1:0] xb_temp;
reg[DATA_WIDTH+1:0] yb_temp;
reg[DATA_WIDTH+1:0] xc_temp;
reg[DATA_WIDTH+1:0] yc_temp;
reg[DATA_WIDTH+1:0] xd_temp;
reg[DATA_WIDTH+1:0] yd_temp;
reg ctrl_in_s2;

always@(posedge clk)
begin
  xa_temp <= xapc + xbpd;
  ya_temp <= yapc + ybpd;
  xb_temp <= xamc + ybmd;
  yb_temp <= yamc - xbmd;
  xc_temp <= xapc - xbpd;
  yc_temp <= yapc - ybpd;
  xd_temp <= xamc - ybmd;
  yd_temp <= yamc + xbmd;
	ctrl_in_s2 <= ctrl_in_s1;
end

assign data_out = {xa_temp,ya_temp,xb_temp,yb_temp,xc_temp,yc_temp,xd_temp,yd_temp};  //!!!order
assign ctrl_out = ctrl_in_s2;

endmodule

