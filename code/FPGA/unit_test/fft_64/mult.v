`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:58:38 03/09/2013 
// Design Name: 
// Module Name:    mult 
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
module mult(clk, ina, inb, product);
	parameter SIZE_A = 16;
	parameter SIZE_B = 8;
	parameter PIPE_LEVEL = 1; //output reg is not included
	
	input clk;
	input signed[SIZE_A-1:0] ina;
	input signed[SIZE_B-1:0] inb;
	output signed[SIZE_A+SIZE_B-1:0] product;
	
	reg signed[SIZE_A-1:0] a;
	reg signed[SIZE_B-1:0] b;
	
	reg signed[SIZE_A+SIZE_B-1:0] partial[PIPE_LEVEL-1:0];
	
	integer i;
	always @(posedge clk)
	begin
	  a <= ina;
	  b <= inb;
	end
	
	always @(posedge clk)
	  partial[0] <= a * b;
	
	always @(posedge clk)
	for (i = 1;i < PIPE_LEVEL; i=i+1)
	  partial[i] <= partial[i-1];
	
	assign product = partial[PIPE_LEVEL-1];
endmodule


module adder(op, ina, inb, res);
parameter SIZE_A = 16;
parameter SIZE_B = 16;
parameter SIZE_O = 17;

input op;
input signed[SIZE_A-1:0] ina;
input signed[SIZE_B-1:0] inb;
output reg signed[SIZE_O-1:0] res;


always @(ina or inb or op)
begin
if (op==1'b0) res = ina + inb;
else res = ina - inb;
end

endmodule