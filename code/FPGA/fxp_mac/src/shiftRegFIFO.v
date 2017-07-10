module shiftRegFIFO(X, Y, clk);
   parameter depth=1, width=1;

   output [width-1:0] Y;
   input  [width-1:0] X;
   input              clk;

   reg [width-1:0]    mem [depth-1:0];
   integer            index;

   assign Y = mem[depth-1];

   always @ (posedge clk) begin
      for(index=1;index<depth;index=index+1) begin
         mem[index] <= mem[index-1];
      end
      mem[0]<=X;
   end
endmodule