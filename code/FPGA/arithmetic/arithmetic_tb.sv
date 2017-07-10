`include "common.vh"

module fpt_mult_tb (out);
	output fpt out;

	reg clk;
	fpt ip1,ip2;
	initial begin
		clk = 0;
		ip1 = 0;
		ip2 = 0;
	end

	always #10 clk <= ~clk;

	fpt_mult uut (.clk(clk),.ip1(ip1),.ip2(ip2),.op(out));

	always@(posedge clk) begin
		ip1 <= ip1 + 16'h0200;
		ip2 <= ip2 + 16'h0300;
	end

endmodule