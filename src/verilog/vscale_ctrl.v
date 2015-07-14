 `include "vscale_ctrl_constants.vh"
 `include "vscale_alu_ops.vh"
 `include "rv32_opcodes.vh"
 `include "vscale_csr_addr_map.vh"

 module vscale_ctrl(
		    input 			       clk,
		    input 			       reset,
		    input [`INST_WIDTH-1:0] 	       inst_DX,
		    input 			       imem_wait,
		    input 			       imem_badmem_e,
		    input 			       dmem_wait,
		    input 			       dmem_badmem_e,
		    input 			       cmp_true,
		    input [`PRV_WIDTH-1:0] 	       prv,
		    output reg [`PC_SRC_SEL_WIDTH-1:0] PC_src_sel,
		    output reg [`IMM_TYPE_WIDTH-1:0]   imm_type,
		    output 			       bypass_rs1,
		    output 			       bypass_rs2,
		    output reg [`SRC_A_SEL_WIDTH-1:0]  src_a_sel,
		    output reg [`SRC_B_SEL_WIDTH-1:0]  src_b_sel,
		    output reg [`ALU_OP_WIDTH-1:0]     alu_op,
		    output wire 		       dmem_en,
		    output wire 		       dmem_wen,
		    output wire [2:0] 		       dmem_size,
		    output wire 		       eret,
		    output reg [`CSR_CMD_WIDTH-1:0]    csr_cmd,
		    output reg 			       csr_imm_sel,
		    input 			       illegal_csr_access,
		    output wire 		       wr_reg_WB,
		    output reg [`REG_ADDR_WIDTH-1:0]   reg_to_wr_WB,
		    output reg [`WB_SRC_SEL_WIDTH-1:0] wb_src_sel_WB,
		    output wire 		       stall_IF,
		    output wire 		       kill_IF,
		    output wire 		       stall_DX,
		    output wire 		       kill_DX,
		    output wire 		       stall_WB,
		    output wire 		       kill_WB,
		    output wire 		       exception_WB,
		    output wire [`ECODE_WIDTH-1:0]     exception_code_WB,
		    output wire 		       retire_WB
                   );

   // IF stage ctrl pipeline registers
   reg                                                replay_IF;
   
   // IF stage ctrl signals
   wire                                               ex_IF;
    
   // DX stage ctrl pipeline registers
   reg                                                had_ex_DX;
    
   // DX stage ctrl signals
   wire [6:0]                                         opcode = inst_DX[6:0];
   wire [6:0]                                         funct7 = inst_DX[31:25];
   wire [11:0] 					      funct12 = inst_DX[31:20];
   wire [2:0]                                         funct3 = inst_DX[14:12];
   wire [`REG_ADDR_WIDTH-1:0] 			      rs1_addr = inst_DX[19:15];
   wire [`REG_ADDR_WIDTH-1:0] 			      rs2_addr = inst_DX[24:20];
   wire [`REG_ADDR_WIDTH-1:0]                         reg_to_wr_DX = inst_DX[11:7];
   reg 						      illegal_instruction;
   reg 						      ebreak;
   reg 						      ecall;
   reg 						      eret_unkilled;
   reg 						      fence_i;   
   wire [`ALU_OP_WIDTH-1:0]                           add_or_sub;
   wire [`ALU_OP_WIDTH-1:0]                           srl_or_sra;
   reg [`ALU_OP_WIDTH-1:0]                            alu_op_arith;
   reg 						      branch_taken_unkilled;
   wire 					      branch_taken;
   reg 						      dmem_en_unkilled;
   reg 						      dmem_wen_unkilled;
   reg 						      jal_unkilled;
   wire 					      jal;
   reg 						      jalr_unkilled;
   wire 					      jalr;
   wire 					      redirect;
   reg 						      wr_reg_unkilled_DX;
   wire 					      wr_reg_DX;
   reg 						      wb_src_sel_DX;
   wire 					      new_ex_DX;
   wire 					      ex_DX;
   reg 						      ex_code_DX;
      
   // WB stage ctrl pipeline registers
   reg                               wr_reg_unkilled_WB;
   reg                               had_ex_WB;
   reg [`ECODE_WIDTH-1:0]            prev_ex_code_WB;
   reg 				     store_in_WB;
   
   // WB stage ctrl signals
   wire                              ex_WB;
   reg [`ECODE_WIDTH-1:0]            ex_code_WB;
   wire 			     dmem_access_exception;
   wire 			     exception;
   assign exception = ex_WB;

   // Hazard signals
   wire 			     load_use;
   reg 				     uses_rs1;
   reg 				     uses_rs2;
   wire 			     raw_rs1;
   wire 			     raw_rs2;

   // IF stage ctrl
   
   always @(posedge clk) begin
      if (reset) begin
         replay_IF <= 1'b1;
      end else begin
         replay_IF <= (redirect && imem_wait) || (fence_i && store_in_WB);
      end
   end

   assign kill_IF = stall_IF || ex_IF || ex_DX || ex_WB || redirect || replay_IF;
   assign stall_IF = (imem_wait && !redirect || stall_DX) && !exception;
   assign ex_IF = imem_badmem_e && !imem_wait && !redirect && !replay_IF;

   // DX stage ctrl

   always @(posedge clk) begin
      if (reset || (kill_IF && !stall_DX)) begin
         had_ex_DX <= 0;
      end else if (!stall_DX) begin
         had_ex_DX <= ex_IF;
      end
   end

   assign kill_DX = stall_DX || ex_DX || ex_WB;
   assign stall_DX = stall_WB || load_use || (fence_i && store_in_WB);
   assign new_ex_DX = ebreak || ecall;
   assign ex_DX = had_ex_DX || ((new_ex_DX) && !stall_DX); // TODO: add causes

   always @(*) begin
      ex_code_DX = `ECODE_INST_ADDR_MISALIGNED;
      if (had_ex_DX) begin
	 ex_code_DX = `ECODE_INST_ADDR_MISALIGNED;
      end else if (illegal_instruction) begin
	 ex_code_DX = `ECODE_ILLEGAL_INST;
      end else if (illegal_csr_access) begin
	 ex_code_DX = `ECODE_ILLEGAL_INST;
      end else if (ebreak) begin
	 ex_code_DX = `ECODE_BREAKPOINT;
      end else if (ecall) begin
	 ex_code_DX = `ECODE_ECALL_FROM_U + prv;
      end
   end // always @ begin
   
   
   /*
    Note: the convention is to use an initial default
    assignment for all control signals (except for
    illegal instructions) and override the default
    values when appropriate, rather than using the
    default keyword. The exception is for illegal
    instructions; in the interest of brevity, this
    signal is set in the default case of any case
    statement after initially being zero.
    */
   
   assign dmem_size = funct3;
   
   always @(*) begin
      illegal_instruction = 1'b0;
      csr_cmd = `CSR_IDLE;
      csr_imm_sel = funct3[2];
      ecall = 1'b0;
      ebreak = 1'b0;
      eret_unkilled = 1'b0;
      fence_i = 1'b0;
      branch_taken_unkilled = 1'b0;
      jal_unkilled = 1'b0;
      jalr_unkilled = 1'b0;
      uses_rs1 = 1'b1;
      uses_rs2 = 1'b0;
      imm_type = `IMM_I;
      src_a_sel = `SRC_A_RS1;
      src_b_sel = `SRC_B_IMM;
      alu_op = `ALU_OP_ADD;
      dmem_en_unkilled = 1'b0;
      dmem_wen_unkilled = 1'b0;
      wr_reg_unkilled_DX = 1'b0;
      wb_src_sel_DX = `WB_SRC_ALU;
      case (opcode)
	`RV32_LOAD : begin
	   dmem_en_unkilled = 1'b1;
	   wr_reg_unkilled_DX = 1'b1;
	   wb_src_sel_DX = `WB_SRC_MEM;
	end
	`RV32_STORE : begin
	   uses_rs2 = 1'b1;
	   imm_type = `IMM_S;
	   dmem_en_unkilled = 1'b1;
	   dmem_wen_unkilled = 1'b1;
	end
	`RV32_BRANCH : begin
	   branch_taken_unkilled = cmp_true;
	   src_b_sel = `SRC_B_RS2;
	   case (funct3)
	     `RV32_FUNCT3_BEQ : alu_op = `ALU_OP_SEQ;
	     `RV32_FUNCT3_BNE : alu_op = `ALU_OP_SNE;
	     `RV32_FUNCT3_BLT : alu_op = `ALU_OP_SLT;
	     `RV32_FUNCT3_BLTU : alu_op = `ALU_OP_SLTU;
	     `RV32_FUNCT3_BGE : alu_op = `ALU_OP_SGE;
	     `RV32_FUNCT3_BGEU : alu_op = `ALU_OP_SGEU;
	     default : illegal_instruction = 1'b1;
	   endcase // case (funct3)
	end
	`RV32_JAL : begin
	   jal_unkilled = 1'b1;
	   uses_rs1 = 1'b0;
	   src_a_sel = `SRC_A_PC;
	   src_b_sel = `SRC_B_FOUR;
	   wr_reg_unkilled_DX = 1'b1;
	end
	`RV32_JALR : begin
	   illegal_instruction = (funct3 != 0);
	   jalr_unkilled = 1'b1;
	   src_a_sel = `SRC_A_PC;
	   src_b_sel = `SRC_B_FOUR;
	   wr_reg_unkilled_DX = 1'b1;
	end
	`RV32_MISC_MEM : begin
	   case (funct3)
	     `RV32_FUNCT3_FENCE : begin
		if ((inst_DX[31:20] == 0) && (rs1_addr == 0) && (reg_to_wr_DX != 0))
		  ; // most fences are no-ops
		else
		  illegal_instruction = 1'b1;
	     end
	     `RV32_FUNCT3_FENCE_I : begin
		if ((inst_DX[31:20] == 0) && (rs1_addr == 0) && (reg_to_wr_DX != 0))
		  fence_i = 1'b1;
		else
		  illegal_instruction = 1'b1;
	     end
	     default : illegal_instruction = 1'b1;
	   endcase // case (funct3)
	end
	`RV32_OP_IMM : begin
	   alu_op = alu_op_arith;
	   wr_reg_unkilled_DX = 1'b1;	   
	end
	`RV32_OP  : begin
	   uses_rs2 = 1'b1;
	   src_b_sel = `SRC_B_RS2;
	   alu_op = alu_op_arith;
	   wr_reg_unkilled_DX = 1'b1;
	end
	`RV32_SYSTEM : begin
	   wb_src_sel_DX = `WB_SRC_CSR;
	   case (funct3)
	     `RV32_FUNCT3_PRIV : begin
		if ((rs1_addr == 0) && (reg_to_wr_DX == 0)) begin
		   case (funct12)
		     `RV32_FUNCT12_ECALL : ecall = 1'b1;
		     `RV32_FUNCT12_EBREAK : ebreak = 1'b1;
		     `RV32_FUNCT12_ERET : begin
			if (prv == 0)
			  illegal_instruction = 1'b1;
			else
			  eret_unkilled = 1'b1;
		     end
		     default : illegal_instruction = 1'b1;
		   endcase // case (funct12)
		end // if ((rs1_addr == 0) && (reg_to_wr_DX == 0))
	     end // case: `RV32_FUNCT3_PRIV
	     `RV32_FUNCT3_CSRRW : csr_cmd = (rs1_addr == 0) ? `CSR_READ : `CSR_WRITE;
	     `RV32_FUNCT3_CSRRS : csr_cmd = (rs1_addr == 0) ? `CSR_READ : `CSR_SET;
	     `RV32_FUNCT3_CSRRC : csr_cmd = (rs1_addr == 0) ? `CSR_READ : `CSR_CLEAR;
	     `RV32_FUNCT3_CSRRWI : csr_cmd = (rs1_addr == 0) ? `CSR_READ : `CSR_WRITE;
	     `RV32_FUNCT3_CSRRSI : csr_cmd = (rs1_addr == 0) ? `CSR_READ : `CSR_SET;
	     `RV32_FUNCT3_CSRRCI : csr_cmd = (rs1_addr == 0) ? `CSR_READ : `CSR_CLEAR;
	     default : illegal_instruction = 1'b1;
	   endcase // case (funct3)
	end
	`RV32_AUIPC : begin
	   uses_rs1 = 1'b0;
	   src_a_sel = `SRC_A_PC;
	   imm_type = `IMM_U;
	   wr_reg_unkilled_DX = 1'b1;
	end
	`RV32_LUI : begin
	   uses_rs1 = 1'b0;
	   src_a_sel = `SRC_A_ZERO;
	   imm_type = `IMM_U;
	   wr_reg_unkilled_DX = 1'b1;
	end
	default : begin
	   illegal_instruction = 1'b1;
	end	
      endcase // case (opcode)
   end // always @ (*)

   assign add_or_sub = ((opcode == `RV32_OP) && (funct7[4])) ? `ALU_OP_SUB : `ALU_OP_ADD;
   assign srl_or_sra = (funct7[4]) ? `ALU_OP_SRA : `ALU_OP_SRL;
   
   always @(*) begin
      case (funct3)
        `RV32_FUNCT3_ADD_SUB : alu_op_arith = add_or_sub;
        `RV32_FUNCT3_SLL : alu_op_arith = `ALU_OP_SLL;
        `RV32_FUNCT3_SLT : alu_op_arith = `ALU_OP_SLT;
        `RV32_FUNCT3_SLTU : alu_op_arith = `ALU_OP_SLTU;
        `RV32_FUNCT3_XOR : alu_op_arith = `ALU_OP_XOR;
        `RV32_FUNCT3_SRA_SRL : alu_op_arith = srl_or_sra;
        `RV32_FUNCT3_OR : alu_op_arith = `ALU_OP_OR;
        `RV32_FUNCT3_AND : alu_op_arith = `ALU_OP_AND;
        default : alu_op_arith = `ALU_OP_ADD;
      endcase // case (funct3)
   end // always @ begin
   
   assign branch_taken = branch_taken_unkilled && !kill_DX;
   assign jal = jal_unkilled && !kill_DX;
   assign jalr = jalr_unkilled && !kill_DX;
   assign eret = eret_unkilled && !kill_DX;
   assign dmem_en = dmem_en_unkilled && !kill_DX;
   assign dmem_wen = dmem_wen_unkilled && !kill_DX;
   assign wr_reg_DX = wr_reg_unkilled_DX && !kill_DX;

   assign redirect = branch_taken || jal || jalr || eret;

   always @(*) begin
      if (exception) begin
         PC_src_sel = `PC_HANDLER;
      end else if (replay_IF) begin
	 PC_src_sel = `PC_REPLAY;
      end else if (eret) begin
	 PC_src_sel = `PC_EPC;
      end else if (branch_taken) begin
         PC_src_sel = `PC_BRANCH_TARGET;
      end else if (jal) begin
         PC_src_sel = `PC_JAL_TARGET;
      end else if (jalr) begin
         PC_src_sel = `PC_JALR_TARGET;
      end else begin
         PC_src_sel = `PC_PLUS_FOUR;
      end
   end // always @ begin

   // WB stage ctrl
   
   always @(posedge clk) begin
      if (reset || (kill_DX && !stall_WB)) begin
         wr_reg_unkilled_WB <= 0;
         had_ex_WB <= 0;
	 store_in_WB <= 0;
      end else if (!stall_WB) begin
         wr_reg_unkilled_WB <= wr_reg_DX;
         wb_src_sel_WB <= wb_src_sel_DX;
         had_ex_WB <= ex_DX;
	 prev_ex_code_WB <= ex_code_DX;
         reg_to_wr_WB <= reg_to_wr_DX;
	 store_in_WB <= dmem_wen;
      end
   end
   
   assign kill_WB = stall_WB || ex_WB;
   assign stall_WB = dmem_wait;
   assign dmem_access_exception = dmem_badmem_e && !stall_WB; 
   assign ex_WB = had_ex_WB || dmem_access_exception;

   always @(*) begin
      ex_code_WB = prev_ex_code_WB;
      if (!had_ex_WB) begin
	 if (dmem_access_exception) begin
	    ex_code_WB = wr_reg_unkilled_WB ?
		      `ECODE_LOAD_ADDR_MISALIGNED :
		      `ECODE_STORE_AMO_ADDR_MISALIGNED;
	 end
      end
   end
   
   assign exception_WB = ex_WB;
   assign exception_code_WB = ex_code_WB;
   assign wr_reg_WB = wr_reg_unkilled_WB && !kill_WB;
   assign retire_WB = !kill_WB;
   
   // Hazard logic
   
   assign raw_rs1 = wr_reg_WB && (rs1_addr == reg_to_wr_WB)
     && (rs1_addr != 0) && uses_rs1;
   assign bypass_rs1 = (wb_src_sel_WB == `WB_SRC_ALU) && raw_rs1;
   
   assign raw_rs2 = wr_reg_WB && (rs2_addr == reg_to_wr_WB)
     && (rs2_addr != 0) && uses_rs2;
   assign bypass_rs2 = (wb_src_sel_WB == `WB_SRC_ALU) && raw_rs2;
   
   assign load_use = (wb_src_sel_WB == `WB_SRC_MEM) && (raw_rs1 || raw_rs2);
   
endmodule // vscale_ctrl
