
`ifndef COMMON_VH
`define COMMON_VH
/*
typedef struct packed {
  logic [31:0] r;
  logic [31:0] i;
} complex_t;
*/
`define FPT_INT_WIDTH 8
`define FPT_TOTAL_WIDTH 16
`define FPT_MSB `FPT_INT_WIDTH-1
`define FPT_EXT0 16'h0000
`define FPT_EXT1 16'hFFFF

typedef reg [`FPT_INT_WIDTH-1:-(`FPT_TOTAL_WIDTH-`FPT_INT_WIDTH)] fpt;
typedef reg [2*`FPT_TOTAL_WIDTH-1:0] fpt_mul;
typedef fpt cpx [1:0];



`endif