
`include "common.vh"

module delay_accumulator_tb(
    output complex_t delay_accum_out
);
  reg clk;
  reg reset;
  reg next;
  wire next_out;

  reg [3:0] counter;

  initial begin
    clk = 0;
  end

  always #10 clk <= ~clk;

  complex_t test_in;
   
  delay_accumulator uut (
    .clk     (clk),
    .reset   (reset),
    .in      (test_in),
    .out     (delay_accum_out),
    .next    (next),
    .next_out(next_out)
    );

  // test vector
  initial begin
    reset = 1;
    #15;
    reset = 0;
    next = 1;
    @(posedge clk);
    next = 0;
  end

  always@(posedge clk) begin
    if (reset) begin
      test_in <= '{32'h43480000, 32'h43480000};
      counter <= 0;
    end else if (counter != 11) begin
      test_in.r <= test_in.r + 32'h00010000;
      test_in.i <= test_in.i + 32'h00010000;
      counter <= counter + 1;
    end
  end

endmodule


module accumulator_tb(
    output complex_t accum_out,
    output complex_t debug_out
);
  reg clk;
  reg reset;
  reg enable;

  initial begin
    clk = 0;
  end

  always #10 clk <= ~clk;

  complex_t in,out_temp;
  reg start, stop;
  wire output_valid;
  reg[3:0] counter_db;
  // complexAdd is delaying 11 cycles to produce the first output.
  // uut specific
  accumulator uut (
    .clk         (clk),
    .reset       (reset),
    .in          (in),
    .out_1         (out_temp),
    .out            (accum_out),
    .start       (start),
    .stop        (stop),
    .output_valid(output_valid),
    .counter_db  (counter_db)
    );
    

  reg [31:0] counter;

  initial begin
    start = 0;
    stop = 0;
    reset = 1;
    #15;
    reset = 0;
    @(posedge clk);
    start = 1;
    @(posedge clk);
    start = 0;
    repeat(64) @(posedge clk);
    stop = 1;
    @(posedge clk);
    stop = 0;
    @(posedge output_valid);
    @(posedge clk);
    #1;
    $display("output is %h + j * %h", accum_out.r, accum_out.i);
  end

  complex_t debug_in;
  always@(posedge clk) begin
    if (reset) begin
      in <= '{32'h43480000, 32'h43480000};
      counter <= 0;
      enable <= 0;
    end else begin
      enable <= 1;

      counter <= counter + 1;
      if (counter == 0) begin
        debug_in.r <= 32'h43480000;
        debug_in.i <= 32'h43480000;
      end else begin
        debug_in.r <= 0;
        debug_in.i <= 0;
      end
    end
  end
  // Trying to understand how the complex adder works. 
  complexAdd debug (
    .clk     (clk),
    .reset   (reset),
    .in0     (debug_in),
    .in1     (debug_in),
    .out     (debug_out),
    .next    (),
    .next_out()
    );

endmodule
