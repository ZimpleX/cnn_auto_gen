// These are all floating point arithmetics
`include "common.vh"

module complexMultConventionfp32fp32 (
  input clk,
  input reset,
  // data
  input complex_t in0,
  input complex_t in1,
  output complex_t out,
  // control signal
  input next,
  output next_out
  );
  
  // instantiate 4 multfp32fp32 and 1 addfp32, 1 subfp32
  wire [31:0] real_real_out;
  wire [31:0] imag_imag_out;
  wire [31:0] real_imag_out;
  wire [31:0] imag_real_out;
  multfp32fp32 real_real(.clk(clk), .enable(1'b1), .rst(reset), .a(in0.r), .b(in1.r), .out(real_real_out));
  multfp32fp32 real_imag(.clk(clk), .enable(1'b1), .rst(reset), .a(in0.r), .b(in1.i), .out(real_imag_out));
  multfp32fp32 imag_real(.clk(clk), .enable(1'b1), .rst(reset), .a(in0.i), .b(in1.r), .out(imag_real_out));
  multfp32fp32 imag_imag(.clk(clk), .enable(1'b1), .rst(reset), .a(in0.i), .b(in1.i), .out(imag_imag_out));
  subfp32 real_out(.clk(clk), .enable(1'b1), .rst(reset), .a(real_real_out), .b(imag_imag_out), .out(out.r));
  addfp32 imag_out(.clk(clk), .enable(1'b1), .rst(reset), .a(real_imag_out), .b(imag_real_out), .out(out.i));

  // multiplier delay: 8, adder delay: 11
  shiftRegFIFO #(19, 1) shiftFIFO_complex(.X(next), .Y(next_out), .clk(clk));

endmodule

module complexMultCanonicalfp32fp32 (
  input clk,
  input reset,
  // data
  input complex_t in0,
  input complex_t in1,
  output complex_t out,
  // control signal
  input next,
  output next_out
  );

  wire [31:0] r0_minus_i0;
  wire [31:0] r1_minus_i1;
  wire [31:0] r1_add_i1;
  wire [31:0] r0_reg, r1_reg, i0_reg;
  wire [31:0] mult0_result, mult1_result, mult2_result;
  shiftRegFIFO #(11, 32) shiftFIFO_r0(.X(in0.r), .Y(r0_reg), .clk(clk));
  shiftRegFIFO #(11, 32) shiftFIFO_r1(.X(in1.r), .Y(r1_reg), .clk(clk));
  shiftRegFIFO #(11, 32) shiftFIFO_i1(.X(in0.i), .Y(i0_reg), .clk(clk));
  subfp32 sub0(.clk(clk), .enable(1'b1), .rst(reset), .a(in0.r), .b(in0.i), .out(r0_minus_i0));
  subfp32 sub1(.clk(clk), .enable(1'b1), .rst(reset), .a(in1.r), .b(in1.i), .out(r1_minus_i1));
  addfp32 add0(.clk(clk), .enable(1'b1), .rst(reset), .a(in1.r), .b(in1.i), .out(r1_add_i1));
  multfp32fp32 mult0(.clk(clk), .enable(1'b1), .rst(reset), .a(r0_minus_i0), .b(r1_reg), .out(mult0_result));
  multfp32fp32 mult1(.clk(clk), .enable(1'b1), .rst(reset), .a(i0_reg), .b(r1_minus_i1), .out(mult1_result));
  multfp32fp32 mult2(.clk(clk), .enable(1'b1), .rst(reset), .a(r1_add_i1), .b(r0_reg), .out(mult2_result));
  addfp32 add1(.clk(clk), .enable(1'b1), .rst(reset), .a(mult0_result), .b(mult1_result), .out(out.r));
  subfp32 sub2(.clk(clk), .enable(1'b1), .rst(reset), .a(mult2_result), .b(mult0_result), .out(out.i));

  // delay 11 + 8 + 11 = 30
  shiftRegFIFO #(30, 1) shiftFIFO_complex(.X(next), .Y(next_out), .clk(clk));

endmodule

module complexAdd (
  input clk,    // Clock
  input reset, // Reset
  // data
  input complex_t in0,
  input complex_t in1,
  output complex_t out,
  // control signal
  input next,
  output next_out
);

  addfp32 adder_real(.clk(clk), .enable(1'b1), .rst(reset), .a(in0.r), .b(in1.r), .out(out.r));
  addfp32 adder_imag(.clk(clk), .enable(1'b1), .rst(reset), .a(in0.i), .b(in1.i), .out(out.i));

  // delay 11
  shiftRegFIFO #(11, 1) shiftFIFO_compplex_add(.X(next), .Y(next_out), .clk(clk));

endmodule

module multfp32fp32(clk, enable, rst, a, b, out);
   input [31:0] a, b;
   output [31:0] out;
   input  clk, enable, rst;

   wire signA, signB; 
   wire [7:0] expA, expB;
   wire [23:0] sigA, sigB;

   assign signA=b[31];
   assign expA=b[30:23];
   assign sigA={1'b1,b[22:0]};

   assign signB=a[31];
   assign expB=a[30:23];
   assign sigB={1'b1,a[22:0]};
   
   reg    signP_m0;
   reg [8:0] expP_m0;

   wire [47:0] mult_res0;
   
   
   multfxp24fxp24 mult(clk, enable, rst, sigA, sigB, mult_res0);

   reg         isNaN_a0, isNaN_b0, isZero_a0, isZero_b0, isInf_a0, isInf_b0;   

   wire        sigAZero, sigBZero;
   
   assign      sigAZero = (sigA[22:0] == 0);
   assign      sigBZero = (sigB[22:0] == 0);
      
   // stage 1 mult stage 1
   always@(posedge clk) if (enable) begin
      isNaN_a0 <= (expA == 8'hff) && !sigAZero;
      isNaN_b0 <= (expB == 8'hff) && !sigBZero;

      isZero_a0 <= (expA == 8'h00);
      isZero_b0 <= (expB == 8'h00);

      isInf_a0 <= (expA == 8'hff) && sigAZero;
      isInf_b0 <= (expB == 8'hff) && sigBZero;
      
      signP_m0 <= signA != signB;
      expP_m0 <= expA + expB;
   end 

   reg signP_m1, zero_m1, inf_m1, nan_m1, under_m1;
   reg [8:0] expP_m1;

   // stage 2 mult stage 2
   always@(posedge clk) if (enable) begin
      zero_m1 <= isZero_a0 || isZero_b0;
      inf_m1 <= isInf_a0 || isInf_b0;
      nan_m1 <= isNaN_a0 || isNaN_b0;
      under_m1 <= (expP_m0 < 128);
      
      signP_m1 <= signP_m0;
      expP_m1 <= expP_m0 - 127;
   end 

   reg signP_m2, zero_m2, inf_m2, nan_m2; 
   reg [8:0] expP_m2;

   // stage 3 mult stage 3
   always@(posedge clk) if (enable) begin
      zero_m2 <= zero_m1 || under_m1;
      inf_m2 <= (inf_m1 || (expP_m1[8] && ~under_m1));
      nan_m2 <= nan_m1 || (zero_m1 && inf_m1); // 0 * infty = NaN
            
      signP_m2<=signP_m1;      
      expP_m2<=expP_m1;
   end 

   reg signP_m3, zero_m3, inf_m3, nan_m3; 
   reg [8:0] expP_m3;

   // stage 4 mult stage 4
   always@(posedge clk) if (enable) begin
      zero_m3 <= zero_m2;
      inf_m3 <= (inf_m2 || (expP_m2 == 9'h0ff));
      nan_m3 <= nan_m2;
      
      signP_m3<=signP_m2;
      expP_m3<=expP_m2;
   end 

   reg signP_m4, zero_m4, inf_m4, nan_m4; 
   reg [8:0] expP_m4;

   // stage 5 mult stage 5
   always@(posedge clk) if (enable) begin
      zero_m4 <= zero_m3;
      inf_m4 <= inf_m3;
      nan_m4 <= nan_m3;
      
      signP_m4<=signP_m3;      
      expP_m4<=expP_m3;
   end

   reg signP_m5, zero_m5, inf_m5, nan_m5;
   reg [8:0] expP_m5;

   
   // stage 6 mult stage 6
   always@(posedge clk) if (enable) begin
      zero_m5 <= zero_m4;
      inf_m5 <= inf_m4;
      nan_m5 <= nan_m4;
      
      signP_m5<=signP_m4;      
      expP_m5 <= expP_m4;
      
   end

   reg signP_m6, zero_m6, inf_m6, nan_m6;   
   reg [8:0] expP_m6;
   reg [23:0] sig_m6;

   // stage 7 --  mult output here!
   // normalize product
   always@(posedge clk) if (enable) begin

      zero_m6 <= (zero_m5 || (mult_res0[47:23] == 0));
      nan_m6 <= nan_m5;      
      
      signP_m6 <= signP_m5;      

      if (mult_res0[47] == 1'b1) begin
        expP_m6 <= expP_m5+1;
        sig_m6 <= mult_res0[47:24];
        inf_m6 <= (inf_m5 || (expP_m5 == 9'h0ff));  
      end
      else begin
        expP_m6 <= expP_m5;
        sig_m6 <= mult_res0[46:23];
        inf_m6 <= inf_m5;   
      end  
   end

   reg signP_m7;
   reg [7:0] expP_m7;
   reg [22:0] sig_m7;
   
   // stage 8: cleanup
   always@(posedge clk) if (enable) begin
      signP_m7 <= signP_m6;
      if (inf_m6 || nan_m6)
        expP_m7 <= 8'hff;
      else if (zero_m6)
        expP_m7 <= 8'h00;
      else
        expP_m7 <= expP_m6;

      if (nan_m6)
        sig_m7 <= 1;
      else if (zero_m6 || inf_m6)
        sig_m7 <= 0;
      else
        sig_m7 <= sig_m6[22:0];      
   end

   assign out = {signP_m7, expP_m7, sig_m7};   
   
endmodule


module multfxp24fxp24(clk, enable, rst, a, b, out);
  parameter WIDTH=24, CYCLES=6;
  input  [WIDTH-1:0]   a,b;
  output [2*WIDTH-1:0] out;
  input                clk, rst,enable;
  reg [2*WIDTH-1:0]    q[CYCLES-1:0];
  integer              i;

  assign               out = q[CYCLES-1];

  always @(posedge clk) begin
    q[0] <= a * b;
    for (i = 1; i < CYCLES; i=i+1) begin
        q[i] <= q[i-1];
    end
  end
endmodule 


module subfp32(clk, enable, rst,  a, b, out);

   input [31:0] a, b;
   output [31:0] out;
   input   clk, enable, rst;  

   addfp32 xyz(.clk(clk), .enable(enable), .rst(rst),  .a(a), .b(b^32'h80000000), .out(out));
endmodule

module addfp32(clk, enable, rst,  a, b, out);

   input [31:0] a, b;
   output [31:0] out;
   input   clk, enable, rst;  

   wire [7:0] expA;
   wire [23:0] sigA;

   assign expA=a[30:23];
   assign sigA={1'b1,a[22:0]};
  
   wire [7:0] expB;
   wire [23:0] sigB;

   assign expB=b[30:23];
   assign sigB={1'b1,b[22:0]};

   reg [31:0] Big, Small;
   reg [7:0] expDiff;

   // stage 1 swap A, B
   always@(posedge clk) if (enable) begin
     if (expA>expB) begin
  // A has larger exp
        Big<=a;
       Small<=b;
        expDiff<=expA-expB;
     end else if (expA==expB) begin
        if (sigA>=sigB) begin
    // A has larger sig
          Big<=a;
         Small<=b;
          expDiff<=expA-expB;
        end else begin
          Small<=a;
         Big<=b;
          expDiff<=expB-expA;
        end
     end else begin
        Small<=a;
        Big<=b;
        expDiff<=expB-expA;
     end
  end

  wire signBig; 
  wire [7:0] expBig;
  wire [23:0] sigBig;

  assign signBig=Big[31];
  assign expBig=Big[30:23];
  assign sigBig=(expBig!=0)?{1'b1,Big[22:0]}:0;

  wire signSmall; 
  wire [7:0] expSmall;
  wire [23:0] sigSmall;

  assign signSmall=Small[31];
  assign expSmall=Small[30:23];
  assign sigSmall=(expDiff[7:5]||(expSmall==0))?0:(expDiff[4]?{16'h0000,1'b1,Small[22:16]}:{1'b1,Small[22:0]});

  reg signSum_a0; 
  reg [7:0] expSum_a0;
  reg [23:0] sigBig_a0;
  reg [23:0] sigSmall_a0;
  reg [3:0] expDiff_a0;
  reg add_a0;

  // stage 2 align addend coarse part 1 
  always@(posedge clk) if (enable) begin
    signSum_a0<=signBig;
    expSum_a0<=expBig;
    sigBig_a0<=sigBig;
    sigSmall_a0<=sigSmall;
    expDiff_a0<=expDiff[3:0];
    add_a0<=signSmall==signBig;
  end

  reg signSum_a1; 
  reg [7:0] expSum_a1;
  reg [23:0] sigBig_a1;
  reg [23:0] sigSmall_a1;
  reg [1:0] expDiff_a1;
  reg add_a1;

  // stage 3  align addend fine part 2
  always@(posedge clk) if (enable) begin
    signSum_a1<=signSum_a0;
    expSum_a1<=expSum_a0;
    sigBig_a1<=sigBig_a0;
    expDiff_a1<=expDiff_a0;
    add_a1<=add_a0;

    if (expDiff_a0[3:2]==2'b11) begin
      sigSmall_a1<={12'h000,sigSmall_a0[23:12]};
    end else if (expDiff_a0[3:2]==2'b10) begin
      sigSmall_a1<={8'h00,sigSmall_a0[23:8]};
    end else if (expDiff_a0[3:2]==2'b01) begin
      sigSmall_a1<={4'h0,sigSmall_a0[23:4]};
    end else begin 
      sigSmall_a1<=sigSmall_a0;
    end
  end


  reg signSum_a2; 
  reg [7:0] expSum_a2;
  reg [23:0] sigBig_a2;
  reg [23:0] sigSmall_a2;
  reg add_a2;

  // stage 4  align addend finest part 3
  always@(posedge clk) if (enable) begin
    signSum_a2<=signSum_a1;
    expSum_a2<=expSum_a1;
    sigBig_a2<=sigBig_a1;
    add_a2<=add_a1;

    if (expDiff_a1[1:0]==2'b11) begin
      sigSmall_a2<={3'h0,sigSmall_a1[23:3]};
    end else if (expDiff_a1[1:0]==2'b10) begin
      sigSmall_a2<={2'h0,sigSmall_a1[23:2]};
    end else if (expDiff_a1[1:0]==2'b01) begin
      sigSmall_a2<={1'h0,sigSmall_a1[23:1]};
    end else begin 
      sigSmall_a2<=sigSmall_a1;
    end
  end

  reg signSum_s0; 
  reg [8:0] expSum_s0;
  reg [24:0] sigSum_s0;
  reg of_s0;

  // stage 5  do addition/substraction
  always@(posedge clk) if (enable) begin
    signSum_s0<=signSum_a2;
    expSum_s0<={1'b0,expSum_a2};
    of_s0<=(expSum_a2==8'hff)?1:0;

    if (add_a2) begin 
      sigSum_s0<={1'b0,sigBig_a2}+{1'b0,sigSmall_a2};
    end else begin
      sigSum_s0<={1'b0,sigBig_a2}-{1'b0,sigSmall_a2};
    end
  end


  reg signSum_n0; 
  reg [8:0] expSum_n0;
  reg [23:0] sigSum_n0;
  reg of_n0;
  
  // stage 6  renormalize after add
  always@(posedge clk) if (enable) begin
    signSum_n0<=signSum_s0;
    if (sigSum_s0[24] && (!of_s0)) begin
      expSum_n0<=expSum_s0+1;
      sigSum_n0<=sigSum_s0[24:1];
      of_n0<=(expSum_s0==9'h0fe);
    end else begin
      expSum_n0<=expSum_s0;
      sigSum_n0<=sigSum_s0[23:0];
      of_n0<=of_s0;
    end
  end 

  reg signSum_n1; 
  reg [8:0] expSum_n1;
  reg [23:0] sigSum_n1;
  reg of_n1;

  // stage 7  renormalized after subtract coarse
  always@(posedge clk) if (enable) begin
    signSum_n1<=signSum_n0;
    of_n1<=of_n0;    

    if (sigSum_n0[23:16]==8'h00) begin
      expSum_n1<=expSum_n0-8;
      sigSum_n1<={sigSum_n0[16:0],8'h00};
    end else begin
      expSum_n1<=expSum_n0;
      sigSum_n1<=sigSum_n0;
    end
  end 

  reg signSum_n2; 
  reg [8:0] expSum_n2;
  reg [23:0] sigSum_n2;
  reg of_n2;

  // stage 8  
  always@(posedge clk) if (enable) begin
    signSum_n2<=signSum_n1;
    of_n2<=of_n1;

    if (sigSum_n1[23:16]==8'h00) begin
      expSum_n2<=expSum_n1-8;
      sigSum_n2<={sigSum_n1[16:0],8'h00};
    end else begin
      expSum_n2<=expSum_n1;
      sigSum_n2<=sigSum_n1;
    end
  end 

  reg signSum_n3; 
  reg [8:0] expSum_n3;
  reg [23:0] sigSum_n3;
  reg of_n3;

  // stage 9  
  always@(posedge clk) if (enable) begin
    signSum_n3<=signSum_n2;
    of_n3<=of_n2;

    if (sigSum_n2[23:20]==4'h0) begin
      expSum_n3<=expSum_n2-4;
      sigSum_n3<={sigSum_n2[20:0],4'h0};
    end else begin
      expSum_n3<=expSum_n2;
      sigSum_n3<=sigSum_n2;
    end
  end 


  reg signSum_n4;
  reg [8:0] expSum_n4;
  reg [23:0] sigSum_n4;
  reg of_n4;

  // stage 10  
  always@(posedge clk) if (enable) begin
    signSum_n4<=signSum_n3;
    of_n4<=of_n3;

    if (sigSum_n3[23:20]==4'h0) begin
      expSum_n4<=expSum_n3-4;
      sigSum_n4<={sigSum_n3[20:0],4'h0};
    end else if (sigSum_n3[23:21]==3'b000) begin
      expSum_n4<=expSum_n3-3;
      sigSum_n4<={sigSum_n3[21:0],3'h0};
    end else if (sigSum_n3[23:22]==2'b00) begin
      expSum_n4<=expSum_n3-2;
      sigSum_n4<={sigSum_n3[22:0],2'h0};
    end else if (sigSum_n3[23]==1'b0) begin
      expSum_n4<=expSum_n3-1;
      sigSum_n4<={sigSum_n3[22:0],1'h0};
    end else begin
      expSum_n4<=expSum_n3;
      sigSum_n4<=sigSum_n3;
    end
  end 

  reg signSum_f0; 
  reg [7:0] expSum_f0;
  reg [23:0] sigSum_f0;

  // stage 11 clean-up
  always@(posedge clk) if (enable) begin
    signSum_f0<=signSum_n4;

    if (of_n4) begin 
      expSum_f0<=8'hff;
      sigSum_f0<=0;
    end else if (expSum_n4[8]||(expSum_n4==0)||(sigSum_n4==0)) begin
      expSum_f0<=8'h00;
      sigSum_f0<=0;
    end else begin
      expSum_f0<=expSum_n4[7:0];
      sigSum_f0<=sigSum_n4;
    end
  end

  assign out={signSum_f0, expSum_f0, sigSum_f0[22:0]};

endmodule

module addfxp(a, b, q, clk);

   parameter width = 16, cycles=1;
   
   input signed [width-1:0]  a, b;
   input                     clk;   
   output signed [width-1:0] q;
   reg signed [width-1:0]    res[cycles-1:0];

   assign                    q = res[cycles-1];
   
   integer                   i;   
   
   always @(posedge clk) begin
     res[0] <= a+b;
      for (i=1; i < cycles; i = i+1)
        res[i] <= res[i-1];
      
   end
   
endmodule

module subfxp(a, b, q, clk);

   parameter width = 16, cycles=1;
   
   input signed [width-1:0]  a, b;
   input                     clk;   
   output signed [width-1:0] q;
   reg signed [width-1:0]    res[cycles-1:0];

   assign                    q = res[cycles-1];
   
   integer                   i;   
   
   always @(posedge clk) begin
     res[0] <= a-b;
      for (i=1; i < cycles; i = i+1)
        res[i] <= res[i-1];
      
   end
  
endmodule
