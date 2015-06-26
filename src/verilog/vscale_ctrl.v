module vscale_ctrl(
		   input [31:0]     inst,
		   input 	    imem_wait,
		   input 	    imem_badmem_e,
		   input 	    dmem_wait,
		   input 	    dmem_badmem_e,
		   input 	    cmp_true,
		   output reg [2:0] PC_src_sel,
		   output reg [2:0] imm_type,
		   output reg [2:0] src_a_sel,
		   output reg [2:0] src_b_sel,
		   output reg [3:0] alu_op,
		   output 	    dmem_en,
		   output 	    dmem_wen,
		   output [2:0]     dmem_size,
		   output 	    wr_reg_WB,
		   output reg [2:0] wb_src_WB,
		   output 	    stall_IF,
		   output 	    kill_IF,
		   output 	    exception_IF,
		   output 	    stall_DX,
		   output 	    kill_DX,
		   output 	    exception_DX,
		   output 	    stall_WB,
		   output 	    kill_WB,
		   output 	    exception_WB
		   );

   wire [6:0] opcode = inst[6:0];
   wire [6:0] funct7 = inst[31:25];
   wire [2:0] funct3 = inst[14:12];

   reg 	      wr_reg_DX;
   wire       wb_src_DX;

   reg 	      wr_reg_WB_unkilled;

   always @(*) begin
      if (branch_taken) begin
	 PC_src_sel = `PC_BRANCH_TARGET;
      end else if (opcode == `OP_JAL) begin
	 PC_src_sel = `PC_JUMP_TARGET;
      end else if (opcode == `OP_JALR) begin
	 PC_src_sel = `PC_REG_TARGET;
      end else begin
	 PC_src_sel = `PC_PLUS_FOUR;
      end
   end // always @ begin
   
   always @(*) begin
      case (opcode)
	`OP_IMM : imm_type = `IMM_I;
	`OP_LUI : imm_type = `IMM_U;
	`OP_AUIPC : imm_type = `IMM_U;
	`OP_JAL : imm_type = `IMM_J;
	`OP_LOAD : imm_type = `IMM_I;
	`OP_STORE : imm_type = `IMM_S;
	default : imm_type = `IMM_I;
      endcase // case (opcode)
   end // always @ (*)

   always @(*) begin
      case (opcode)
	`OP_IMM : wr_reg_DX = 1'b1;
	`OP_OP : wr_reg_DX = 1'b1;
	`OP_LUI : wr_reg_DX = 1'b1;
	`OP_AUIPC : wr_reg_DX = 1'b1;
	`OP_JAL : wr_reg_DX = 1'b1;
	`OP_JALR : wr_reg_DX = 1'b1;
	`OP_LOAD : wr_reg_DX = 1'b1;
	default : wr_reg_DX = 1'b0;
      endcase // case (opcode)
   end

   assign wb_src_DX = (opcode == `OP_LOAD) ? `WB_SRC_MEM : jump ? `WB_SRC_JUMP : `WB_SRC_ALU;
   assign dmem_en = ((opcode == `OP_LOAD) || (opcode == `OP_STORE)) && !kill_DX;
   assign dmem_wen = (opcode == `OP_STORE) && !kill_DX;
   assign dmem_size = funct3;

   wire branch_taken = (opcode == `OP_BRANCH) && cmp_true;
   wire jump = (opcode == `OP_JAL) || (opcode == `OP_JALR);
   wire pcp4 = !(branch_taken || jump);

   assign kill_IF = imem_wait || !pcp4;
   assign stall_IF = stall_X || (imem_wait && pcp4);
   assign exception_IF = imem_badmem_e;
 
   
   always @(posedge clk) begin
      if (reset || (kill_IF && !stall_DX)) begin
	 had_exception_DX <= 0;
      end else if (!stall_DX) begin
	 had_exception_DX <= exception_IF;
      end
   end

   assign kill_DX = 0 || imem_wait;
   assign stall_DX = stall_WB || imem_wait;
   assign exception_DX = had_exception_DX;

   
   always @(posedge clk) begin
      if (reset || (kill_DX && !stall_WB)) begin
	 wr_reg_WB <= 0;
	 had_exception_WB <= 0;
      end else if (!stall_WB) begin
	 wr_reg_WB_unkilled <= wr_reg_DX;
	 wb_src_WB <= wb_src_DX;
	 had_exception_WB <= exception_DX;
      end
   end

   assign kill_WB = dmem_wait;
   assign stall_WB = dmem_wait;
   assign exception_WB = had_exception_WB || dmem_badmem_e;
   
   assign wr_reg_WB = wr_reg_WB_unkilled && !kill_WB;
   
endmodule // vscale_ctrl
