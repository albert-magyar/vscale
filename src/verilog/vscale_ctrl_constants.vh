`define RV_NOP 7'b0010011

`define SRC_A_RS1  0
`define SRC_A_PC   1
`define SRC_A_ZERO 2

`define SRC_B_RS2  0
`define SRC_B_IMM  1
`define SRC_B_FOUR 2
`define SRC_B_ZERO 3

`define PC_PLUS_FOUR     0
`define PC_BRANCH_TARGET 1
`define PC_JAL_TARGET    2
`define PC_REG_TARGET    3
`define PC_REPLAY        4
`define PC_STVEC         5

`define IMM_I 0
`define IMM_S 1
`define IMM_U 2
`define IMM_J 3

`define WB_SRC_ALU  0
`define WB_SRC_MEM  1
`define WB_SRC_JUMP 2
