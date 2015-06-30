`include "vscale_ctrl_constants.vh"
`include "rv32_opcodes.vh"

module vscale_PC_mux(
                     input [`PC_SRC_SEL_WIDTH-1:0] PC_src_sel,
                     input [`INST_WIDTH-1:0]           inst_DX,
                     input [`XPR_LEN-1:0]          alu_out,
                     input [`XPR_LEN-1:0]          rs1_data,
                     input [`XPR_LEN-1:0]          PC_IF,
                     input [`XPR_LEN-1:0]          PC_DX,
                     input [`XPR_LEN-1:0]          handler_PC,
                     output reg [`XPR_LEN-1:0]     PC_PIF
                     );

   wire [`XPR_LEN-1:0] imm_b = { {20{inst_DX[31]}}, inst_DX[7], inst_DX[30:25], inst_DX[11:8], 1'b0 };
   wire [`XPR_LEN-1:0] PC_branch = PC_DX + imm_b;
   wire [`XPR_LEN-1:0] PC_plus_4 = PC_IF + 31'h4;
   
   
   always @(*) begin
      case (PC_src_sel)
        `PC_PLUS_FOUR : PC_PIF = PC_plus_4;
        `PC_JAL_TARGET : PC_PIF = alu_out;
        `PC_REG_TARGET : PC_PIF = rs1_data;
        `PC_BRANCH_TARGET : PC_PIF = PC_branch;
        `PC_REPLAY : PC_PIF = PC_IF;
        `PC_HANDLER : PC_PIF = handler_PC;
        default : PC_PIF = PC_plus_4;
      endcase // case (PC_src_sel)
   end // always @ (*)

endmodule // vscale_PC_mux

