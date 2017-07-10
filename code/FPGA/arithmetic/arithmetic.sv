`include "common.vh"

module fpt_mult (clk, ip1, ip2, op);
	input clk;
	input fpt ip1,ip2;
	output fpt op;

	fpt_mul temp, ip1_ext, ip2_ext;
	always @(posedge clk) begin
		ip1_ext <= (ip1[`FPT_MSB]==0) ? {`FPT_EXT0,ip1}:{`FPT_EXT1,ip1};
		ip2_ext <= (ip2[`FPT_MSB]==0) ? {`FPT_EXT0,ip2}:{`FPT_EXT1,ip2};
		temp <= ip1_ext*ip2_ext;
	end

	assign op = temp[(`FPT_TOTAL_WIDTH+`FPT_INT_WIDTH-1):(`FPT_TOTAL_WIDTH-`FPT_INT_WIDTH)];
endmodule


module fpt_add (clk, ip1, ip2, op);
	input clk;
	input fpt ip1,ip2;
	input fpt op;

	always @(posedge clk) begin
		op <= ip1 + ip2;
	end
endmodule


module cpx_fpt_mult (clk, ip1, ip2, op);
	input clk;
	input cpx ip1,ip2;
	output cpx op;

	always @(posedge clk) begin

	end
endmodule