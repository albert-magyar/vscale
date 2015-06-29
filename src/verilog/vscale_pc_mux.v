`include "vscale_ctrl_constants.vh"

module vscale_PC_mux(
		     input [2:0]       PC_src_sel,
		     input [31:0]      inst_DX,
		     input [31:0]      alu_out,
		     input [31:0]      rs1_data,
		     input [31:0]      PC_IF,
		     input [31:0]      PC_DX,
		     input [31:0]      csr_stvec,
		     output reg [31:0] PC_PIF
		     );

   wire [31:0] imm_b = { {20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0 };
   wire [31:0] PC_branch = PC_DX + imm_b;
   wire [31:0] PC_plus_4 = PC_IF + 31'h4;
   
   
   always @(*) begin
      case (PC_src_sel)
	`PC_PLUS_FOUR : next_PC = PC_plus_4;
	`PC_JAL_TARGET : next_PC = alu_out;
	`PC_REG_TARGET : next_PC = rs1_data;
	`PC_BRANCH_TARGET : next_PC = PC_branch;
	`PC_REPLAY : next_PC = PC_IF;
	`PC_STVEC : next_PC = csr_stvec;
	default : next_PC = PC_plus_4;
      endcase // case (PC_src_sel)
   end // always @ (*)

endmodule // vscale_PC_mux

