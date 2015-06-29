`define RV32_LOAD     7'b0000011
`define RV32_STORE    7'b0100011
`define RV32_MADD     7'b1000011
`define RV32_BRANCH   7'b1100011

`define RV32_LOAD_FP  7'b0000111
`define RV32_STORE_FP 7'b0100111 
`define RV32_MSUB     7'b1000111
`define RV32_JALR     7'b1100111

`define RV32_CUSTOM_0 7'b0001011
`define RV32_CUSTOM_1 7'b0101011
`define RV32_NMSUB    7'b1001011
// 1101011 is reserved

`define RV32_MISC_MEM 7'b0001111
`define RV32_AMO      7'b0101111
`define RV32_NMADD    7'b1001111
`define RV32_JAL      7'b1101111

`define RV32_OP_IMM   7'b0010011
`define RV32_OP       7'b0110011
`define RV32_OP_FP    7'b1010011
`define RV32_SYSTEM   7'b1110011

`define RV32_AUIPC    7'b0010111
`define RV32_LUI      7'b0110111
// 1010111 is reserved
// 1110111 is reserved

// 0011011 is RV64-specific
// 0111011 is RV64-specific
`define RV32_CUSTOM_2 1011011
`define RV32_CUSTOM_3 1111011
