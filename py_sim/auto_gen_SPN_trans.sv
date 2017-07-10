// mem stage addr sequences: each addr 
// has 2 bits. SPN fetches addr by slicing 
// each bitstream in a circular manner.
// e.g., addr into mem 1:
//      1,0,3,2,0,1,2,3,...
addr_mem_1 <= 8'b11100100;
addr_mem_2 <= 16'b1110010010110001;
addr_mem_3 <= 16'b1110010001001110;
addr_mem_4 <= 16'b1110010000011011;
