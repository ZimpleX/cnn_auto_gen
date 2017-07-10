module afu_user # (
  parameter DATA_WIDTH = 32,
  parameter BUFF_DEPTH_BITS = 3
) (
  input clk,    // Clock
  input reset,
  // input fifo
  input [511:0] input_fifo_din,
  input input_fifo_we,
  output input_fifo_full,
  output input_fifo_almost_full,
  output [BUFF_DEPTH_BITS:0] input_fifo_count,
  // output fifo
  output [511:0] output_fifo_dout,
  input output_fifo_re,
  output output_fifo_empty,
  output output_fifo_almost_empty,
  // other information
  input [31:0] ctx_length
);
  // input fifo
  wire [511:0] input_fifo_dout;
  wire input_fifo_re;
  wire input_fifo_empty;
  // output fifo
  wire [511:0] output_fifo_din;
  reg output_fifo_we;

  syn_read_fifo #(.FIFO_WIDTH(512),
                  .FIFO_DEPTH_BITS(BUFF_DEPTH_BITS),       // transfer size 1 -> 32 entries
                  .FIFO_ALMOSTFULL_THRESHOLD(2**(BUFF_DEPTH_BITS)-4),
                  .FIFO_ALMOSTEMPTY_THRESHOLD(2)
                 ) input_fifo (
                .clk                (clk),
                .reset              (reset),
                .din                (input_fifo_din),
                .we                 (input_fifo_we),
                .re                 (input_fifo_re),
                .dout               (input_fifo_dout),
                .empty              (input_fifo_empty),
                .almostempty        (),
                .full               (input_fifo_full),
                .count              (input_fifo_count),
                .almostfull         (input_fifo_almost_full)
            );

  wire [15:0] operand_a;
  wire [15:0] operand_b;
  reg start;
  wire stop;
  wire [15:0] out;
  wire [4:0] right_shift_amount;

  assign operand_a = input_fifo_dout[15:0];
  assign operand_b = input_fifo_dout[31:16];

  assign right_shift_amount = 5'b01001;   // 8 bit fraction

  enum {IDLE, RUN} state;
  always@(posedge clk) begin
    if (reset) begin
      state <= IDLE;
    end else begin
      case (state)
        IDLE : if (input_fifo_re) begin state <= RUN; end
        RUN : begin end
        default : begin end
      endcase
    end
  end

  assign start = (state == IDLE) ? 1'b1 : 1'b0;

  reg [4:0] counter;

  always_ff @(posedge clk) begin
    if(reset) begin
      counter <= 0;
    end else if (input_fifo_re) begin
      counter <= counter + 1;
    end
  end

  assign stop = (counter == 5'b11000) ? 1'b1 : 1'b0;

  reg input_data_valid;
  always_ff @(posedge clk) begin
    input_data_valid <= input_fifo_re;
  end

  macfxp16 #(
      .MULTIPLIER_CYCLE(6)
    ) inst_mac_fxp (
      .clk                (clk),
      .clk_en             (input_data_valid),
      .rst                (),
      .operand_a          (operand_a),
      .operand_b          (operand_b),
      .out                (out),
      .start              (start),
      .stop               (stop),
      .output_valid       (output_valid),
      .right_shift_amount (right_shift_amount)
    );

  // input re
  assign input_fifo_re = ~input_fifo_empty;

  always@(posedge clk) begin
    if (output_valid)  begin
      output_fifo_we <= 1'b1;
    end
  end

  assign output_fifo_din = {{496{1'b0}}, {out}};

  syn_read_fifo #(.FIFO_WIDTH(512),
                  .FIFO_DEPTH_BITS(BUFF_DEPTH_BITS),       // transfer size 1 -> 32 entries
                  .FIFO_ALMOSTFULL_THRESHOLD(2**(BUFF_DEPTH_BITS)-4),
                  .FIFO_ALMOSTEMPTY_THRESHOLD(2)
                 ) output_fifo (
                .clk                (clk),
                .reset              (reset),
                .din                (output_fifo_din),
                .we                 (output_fifo_we),
                .re                 (output_fifo_re),
                .dout               (output_fifo_dout),
                .empty              (output_fifo_empty),
                .almostempty        (output_fifo_almost_empty),
                .full               (),
                .count              (),
                .almostfull         ()
            );

endmodule
