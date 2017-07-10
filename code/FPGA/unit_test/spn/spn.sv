`timescale 1ns/1ps

module mux_n(sel,data_in,data_out);

    parameter ADDR = 2;
    parameter NUM_INPUTS = 1<<ADDR;

    input[ADDR-1:0] sel;
    input[NUM_INPUTS-1:0] data_in;
    output data_out;

    assign data_out = data_in[sel];
endmodule



module blk_ram(clk,rst,wen,addr,din,dout);

    parameter DATA_WIDTH = 32;
    parameter MEM_ADDR_WIDTH = 6;
    parameter SIZE_RAM = 1<<MEM_ADDR_WIDTH;

    input clk,rst,wen;
    input[MEM_ADDR_WIDTH-1:0] addr;
    input[DATA_WIDTH-1:0] din;
    output reg[DATA_WIDTH-1:0] dout;

    reg[DATA_WIDTH-1:0] ram[SIZE_RAM-1:0];
    reg[MEM_ADDR_WIDTH:0] i;

    always@(posedge clk)
    begin
        if (rst) begin
            for (i=0; i<SIZE_RAM; i++)
                ram[i] <= 0;
        end else begin
            if (wen) begin
                ram[addr] <= din;
            end
            dout <= ram[addr];
        end
    end
endmodule




module spn(clk,rst,input_stream,output_stream,valid_in,valid_out);

    // let's first test 16 x 16 matrix transpose
    parameter PARA = 4;         // input parallelism: PARA = {}
    parameter MEM_DEPTH = 64;   // memory depth: MEM_DEPTH = {}
    parameter DATA_WIDTH = 32;  // data width for each element
    parameter SEL_WIDTH = 2;    // data width for one mux sel signal
    parameter MEM_ADDR_WIDTH = 6;   // log(MEM_DEPTH,2)

    input clk,rst,valid_in;
    input[DATA_WIDTH-1:0] input_stream[PARA-1:0];
    output valid_out;
    output[DATA_WIDTH-1:0] output_stream[PARA-1:0];

	 reg[DATA_WIDTH-1:0] output_stream_reg[PARA-1:0];
    reg[DATA_WIDTH-1:0] input_delay0[PARA-1:0];
	 reg[DATA_WIDTH-1:0] mem_delay1[PARA-1:0];
	 reg[DATA_WIDTH-1:0] mem_output[PARA-1:0];
	 reg[DATA_WIDTH-1:0] output_delay2[PARA-1:0];
    reg[DATA_WIDTH-1:0] mem_input[PARA-1:0];
    
    reg valid_mem_in,valid_perm2_in;
    reg valid_delay0,valid_delay1,valid_out_reg;
    
    reg[SEL_WIDTH:0] i;

    // [BEGIN] VAR DEF
    // width for one mem addr, or mux sel signal
    reg[5:0] mem_addr[3:0];
    reg[1:0] sel_perm0[3:0];
    reg[1:0] sel_perm2[3:0];

    // counter used for traversing control_* (simply add 1 each cycle)
    reg[6:0] counter_mem_addr_0;
    reg[6:0] counter_mem_addr_1;
    reg[6:0] counter_mem_addr_2;
    reg[6:0] counter_mem_addr_3;

    reg[5:0] counter_perm0;
    reg[5:0] counter_perm2;

    // actual control bits
    reg[767:0] control_mem_0;
    reg[767:0] control_mem_1;
    reg[767:0] control_mem_2;
    reg[767:0] control_mem_3;
    reg[127:0] control_perm0[3:0];
    reg[127:0] control_perm2[3:0];
    // [END] VAR DEF
    genvar g;
    generate 
		for (g=0; g<PARA; g=g+1) begin: mem_chan
			blk_ram #(.DATA_WIDTH(DATA_WIDTH),
            .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH)) ram(clk,rst,valid_delay1,mem_addr[g],mem_delay1[g],mem_output[g]);
		end
	 endgenerate
	 assign valid_out = valid_out_reg;
	 assign output_stream = output_stream_reg;
    always@(posedge clk) begin
        // need to pass in an additional image of all 0 to flush the mem stage.
        // This is ok, since it will also guarantee the 
        if (rst) begin
            // [BEGIN] VAR INIT
            counter_perm0 <= 0;
            counter_perm2 <= 0;
            counter_mem_addr_0 <= 0;
            counter_mem_addr_1 <= 0;
            counter_mem_addr_2 <= 0;
            counter_mem_addr_3 <= 0;

            control_mem_0 <= 768'b111111111110111101111100111011111010111001111000110111110110110101110100110011110010110001110000101111101110101101101100101011101010101001101000100111100110100101100100100011100010100001100000011111011110011101011100011011011010011001011000010111010110010101010100010011010010010001010000001111001110001101001100001011001010001001001000000111000110000101000100000011000010000001000000111111101111011111001111111011101011011011001011110111100111010111000111110011100011010011000011111110101110011110001110111010101010011010001010110110100110010110000110110010100010010010000010111101101101011101001101111001101001011001001001110101100101010101000101110001100001010001000001111100101100011100001100111000101000011000001000110100100100010100000100110000100000010000000000;
            control_mem_1 <= 768'b111111111110111101111100111011111010111001111000110111110110110101110100110011110010110001110000101111101110101101101100101011101010101001101000100111100110100101100100100011100010100001100000011111011110011101011100011011011010011001011000010111010110010101010100010011010010010001010000001111001110001101001100001011001010001001001000000111000110000101000100000011000010000001000000111011101011011011001011111111101111011111001111110011100011010011000011110111100111010111000111111010101010011010001010111110101110011110001110110010100010010010000010110110100110010110000110111001101001011001001001111101101101011101001101110001100001010001000001110101100101010101000101111000101000011000001000111100101100011100001100110000100000010000000000110100100100010100000100;
            control_mem_2 <= 768'b111111111110111101111100111011111010111001111000110111110110110101110100110011110010110001110000101111101110101101101100101011101010101001101000100111100110100101100100100011100010100001100000011111011110011101011100011011011010011001011000010111010110010101010100010011010010010001010000001111001110001101001100001011001010001001001000000111000110000101000100000011000010000001000000110111100111010111000111110011100011010011000011111111101111011111001111111011101011011011001011110110100110010110000110110010100010010010000010111110101110011110001110111010101010011010001010110101100101010101000101110001100001010001000001111101101101011101001101111001101001011001001001110100100100010100000100110000100000010000000000111100101100011100001100111000101000011000001000;
            control_mem_3 <= 768'b111111111110111101111100111011111010111001111000110111110110110101110100110011110010110001110000101111101110101101101100101011101010101001101000100111100110100101100100100011100010100001100000011111011110011101011100011011011010011001011000010111010110010101010100010011010010010001010000001111001110001101001100001011001010001001001000000111000110000101000100000011000010000001000000110011100011010011000011110111100111010111000111111011101011011011001011111111101111011111001111110010100010010010000010110110100110010110000110111010101010011010001010111110101110011110001110110001100001010001000001110101100101010101000101111001101001011001001001111101101101011101001101110000100000010000000000110100100100010100000100111000101000011000001000111100101100011100001100;

            control_perm0[0] <= 128'b11111111101010100101010100000000111111111010101001010101000000001111111110101010010101010000000011111111101010100101010100000000;
            control_perm0[1] <= 128'b10101010111111110000000001010101101010101111111100000000010101011010101011111111000000000101010110101010111111110000000001010101;
            control_perm0[2] <= 128'b01010101000000001111111110101010010101010000000011111111101010100101010100000000111111111010101001010101000000001111111110101010;
            control_perm0[3] <= 128'b00000000010101011010101011111111000000000101010110101010111111110000000001010101101010101111111100000000010101011010101011111111;

            control_perm2[0] <= 128'b11111111101010100101010100000000111111111010101001010101000000001111111110101010010101010000000011111111101010100101010100000000;
            control_perm2[1] <= 128'b10101010111111110000000001010101101010101111111100000000010101011010101011111111000000000101010110101010111111110000000001010101;
            control_perm2[2] <= 128'b01010101000000001111111110101010010101010000000011111111101010100101010100000000111111111010101001010101000000001111111110101010;
            control_perm2[3] <= 128'b00000000010101011010101011111111000000000101010110101010111111110000000001010101101010101111111100000000010101011010101011111111;
                                  
            // [END] VAR INIT
            valid_mem_in <= 0;
            valid_perm2_in <= 0;
            valid_delay0 <= 0;
            valid_delay1 <= 0;
            valid_out_reg <= 0;
        end else begin
            // if in this cycle, the data is valid, then we need to pass-in
            // valid_in to be 1 the cycle before
            valid_delay0 <= valid_in;   // delay for 1 clk
            valid_mem_in <= valid_delay0;
            valid_delay1 <= valid_mem_in;
            valid_perm2_in <= valid_delay1;
            valid_out_reg <= valid_perm2_in;// i will output one wasted image of N x N
                                        // but it is all 0, so it won't affec
                                        
            if (valid_in) begin
            // perm0: get control signal
                counter_perm0 <= counter_perm0+1;
                for (i=0; i<PARA; i=i+1) begin
                    sel_perm0[i] <= control_perm0[i][counter_perm0*SEL_WIDTH+:SEL_WIDTH];
                end
					 input_delay0 <= input_stream;
            end
            if (valid_delay0) begin
            // perm0: mux
                for (i=0; i<PARA; i=i+1)
                    mem_input[i] <= input_delay0[sel_perm0[i]];
            end
            if (valid_mem_in) begin
            // mem: get control signal
                counter_mem_addr_0 <= counter_mem_addr_0+1;
                counter_mem_addr_1 <= counter_mem_addr_1+1;
                counter_mem_addr_2 <= counter_mem_addr_2+1;
                counter_mem_addr_3 <= counter_mem_addr_3+1;
                mem_addr[0] <= control_mem_0[counter_mem_addr_0*MEM_ADDR_WIDTH+:MEM_ADDR_WIDTH];
                mem_addr[1] <= control_mem_1[counter_mem_addr_1*MEM_ADDR_WIDTH+:MEM_ADDR_WIDTH];
                mem_addr[2] <= control_mem_2[counter_mem_addr_2*MEM_ADDR_WIDTH+:MEM_ADDR_WIDTH];
                mem_addr[3] <= control_mem_3[counter_mem_addr_3*MEM_ADDR_WIDTH+:MEM_ADDR_WIDTH];
                mem_delay1 <= mem_input;
            end
            if (valid_delay1) begin
            // mem: ram module handles in/out
            end
            if (valid_perm2_in) begin
            // perm2: get control signal
                counter_perm2 <= counter_perm2+1;
                for (i=0; i<PARA; i=i+1) begin
                    sel_perm2[i] <= control_perm2[i][counter_perm2*SEL_WIDTH+:SEL_WIDTH];
					 end
					 output_delay2 <= mem_output;
            end
            if (valid_out) begin
                for (i=0; i<PARA; i=i+1)
                    output_stream_reg[i] <= output_delay2[sel_perm2[i]];
            end
        end
    end

endmodule
