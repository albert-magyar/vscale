`include "vscale_ctrl_constants.vh"
`include "vscale_alu_ops.vh"
`include "rv32_opcodes.vh"

module vscale_ctrl(
		   input 	     clk,
		   input 	     reset,
		   input [31:0]      inst_DX,
		   input 	     imem_wait,
		   input 	     imem_badmem_e,
		   input 	     dmem_wait,
		   input 	     dmem_badmem_e,
		   input 	     cmp_true,
		   output reg [2:0]  PC_src_sel,
		   output reg [2:0]  imm_type,
		   output reg [2:0]  src_a_sel,
		   output reg [2:0]  src_b_sel,
		   output reg [3:0]  alu_op,
		   output wire 	     dmem_en,
		   output wire 	     dmem_wen,
		   output wire [2:0] dmem_size,
		   output reg 	     wr_reg_WB,
		   output reg 	     reg_to_wr_WB,
		   output reg [2:0]  wb_src_WB,
		   output wire 	     stall_IF,
		   output wire 	     kill_IF,
		   output wire 	     stall_DX,
		   output wire 	     kill_DX,
		   output wire 	     stall_WB,
		   output wire 	     kill_WB,
		   output wire 	     exception
		   );

   // IF stage ctrl pipeline registers
   reg 				     replay_IF;

   // IF stage ctrl signals
   wire 			     ex_IF;
   
   // DX stage ctrl pipeline registers
   reg 				     had_ex_DX;
   
   // DX stage ctrl signals
   wire [6:0] 			     opcode = inst[6:0];
   wire [6:0] 			     funct7 = inst[31:25];
   wire [2:0] 			     funct3 = inst[14:12];
   wire 			     redirect;
   reg 				     wr_reg_DX;
   wire [5:0] 			     reg_to_wr_DX;
   wire 			     wb_src_DX;
   wire 			     ex_DX;
   
   // WB stage ctrl pipeline registers
   reg 				     wr_reg_WB_unkilled;

   // WB stage ctrl signals
   wire 			     ex_WB;

   
   
   // IF stage ctrl
   
   always @(posedge clk) begin
      if (reset) begin
	 replay_IF <= 1'b1;
      end else begin
	 replay_IF <= redirect && imem_wait;
      end
   end

   assign kill_IF = stall_IF || ex_IF || ex_DX || ex_WB || redirect || replay_IF;
   assign stall_IF = (imem_wait && !redirect || stall_DX) && !exception;
   assign ex_IF = imem_badmem_e && !imem_wait && !redirect && !replay;

   // DX stage ctrl
   
   always @(posedge clk) begin
      if (reset || (kill_IF && !stall_DX)) begin
	 had_ex_DX <= 0;
      end else if (!stall_DX) begin
	 had_ex_DX <= ex_IF;
      end
   end

   assign kill_DX = stall_DX || ex_DX || ex_WB;
   assign stall_DX = stall_WB || load_use;
   assign ex_DX = had_ex_DX || ((causes) && !stall_DX);

   assign branch_taken = ((opcode == `RV32_BRANCH) && cmp_true);
   assign jal = (opcode == `RV32_JAL);
   assign jalr = (opcode == `RV32_JALR);

   assign redirect = branch_taken || jal || jalr;
   
   always @(*) begin
      if (exception) begin
	 PC_src_sel = `PC_STVEC;
      end else if (branch_taken) begin
	 PC_src_sel = `PC_BRANCH_TARGET;
      end else if (jal) begin
	 PC_src_sel = `PC_JAL_TARGET;
      end else if (jalr) begin
	 PC_src_sel = `PC_REG_TARGET;
      end else begin
	 PC_src_sel = `PC_PLUS_FOUR;
      end
   end // always @ begin
   
   always @(*) begin
      case (opcode)
	`RV32_OP_IMM : imm_type = `IMM_I;
	`RV32_LUI : imm_type = `IMM_U;
	`RV32_AUIPC : imm_type = `IMM_U;
	`RV32_JAL : imm_type = `IMM_J;
	`RV32_LOAD : imm_type = `IMM_I;
	`RV32_STORE : imm_type = `IMM_S;
	default : imm_type = `IMM_I;
      endcase // case (opcode)
   end // always @ (*)

   always @(*) begin
      case (opcode)
	`RV32_OP_IMM : wr_reg_DX = 1'b1;
	`RV32_OP : wr_reg_DX = 1'b1;
	`RV32_LUI : wr_reg_DX = 1'b1;
	`RV32_AUIPC : wr_reg_DX = 1'b1;
	`RV32_JAL : wr_reg_DX = 1'b1;
	`RV32_JALR : wr_reg_DX = 1'b1;
	`RV32_LOAD : wr_reg_DX = 1'b1;
	default : wr_reg_DX = 1'b0;
      endcase // case (opcode)
   end

   assign reg_to_wr_DX = inst[11:7];
   assign wb_src_DX = (opcode == `RV32_LOAD) ? `WB_SRC_MEM : jump ? `WB_SRC_JUMP : `WB_SRC_ALU;
   assign dmem_en = ((opcode == `RV32_LOAD) || (opcode == `RV32_STORE)) && !kill_DX;
   assign dmem_wen = (opcode == `RV32_STORE) && !kill_DX;
   assign dmem_size = funct3;
   
   // WB stage ctrl
   
   always @(posedge clk) begin
      if (reset || (kill_DX && !stall_WB)) begin
	 wr_reg_WB <= 0;
	 had_ex_WB <= 0;
      end else if (!stall_WB) begin
	 wr_reg_WB_unkilled <= wr_reg_DX;
	 wb_src_WB <= wb_src_DX;
	 had_ex_WB <= ex_DX;
	 reg_to_wr_WB <= reg_to_wr_DX;
      end
   end
   
   assign kill_WB = stall_WB || ex_WB;
   assign stall_WB = dmem_wait;
   assign ex_WB = had_ex_WB || (dmem_badmem_e && !stall_WB);
   assign exception = ex_WB;   
   assign wr_reg_WB = wr_reg_WB_unkilled && !kill_WB;
   
endmodule // vscale_ctrl
