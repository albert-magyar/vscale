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
   reg 						      illegal_opcode;
   wire [`REG_ADDR_WIDTH-1:0] 			      rs1_addr = inst_DX[19:15];
   wire [`REG_ADDR_WIDTH-1:0] 			      rs2_addr = inst_DX[24:20];
   wire [`REG_ADDR_WIDTH-1:0]                         reg_to_wr_DX = inst_DX[11:7];
   wire [`ALU_OP_WIDTH-1:0]                           add_or_sub;
   wire [`ALU_OP_WIDTH-1:0]                           srl_or_sra;
   reg [`ALU_OP_WIDTH-1:0]                            alu_op_arith;
   reg [`ALU_OP_WIDTH-1:0]                            alu_op_branch;
   wire 					      branch_taken;
   wire 					      jal;
   wire 					      jalr;
   wire                                               redirect;
   reg                                                wr_reg_DX;
   wire [`WB_SRC_SEL_WIDTH-1:0]                       wb_src_sel_DX;
   wire                                               ex_DX;
   reg 						      new_ex_DX;
   reg [`ECODE_WIDTH-1:0]                             ex_code_DX;
   
   // WB stage ctrl pipeline registers
   reg                               wr_reg_unkilled_WB;
   reg                               had_ex_WB;
   reg [`ECODE_WIDTH-1:0]            prev_ex_code_WB;
   

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
         replay_IF <= redirect && imem_wait;
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
   assign stall_DX = stall_WB || load_use;
   assign ex_DX = had_ex_DX || ((new_ex_DX) && !stall_DX); // TODO: add causes

   always @(*) begin
      // no other cause possible before DX
      ex_code_DX = `ECODE_INST_ADDR_MISALIGNED;
      new_ex_DX = 0;
      if (!had_ex_DX) begin
	 if (opcode == `RV32_SYSTEM && funct3 == `RV32_FUNCT3_PRIV) begin
	 end // if (opcode == `RV32_SYSTEM && funct3 == `RV32_FUNCT3_PRIV)
	 if (illegal_opcode || illegal_csr_access) begin
	    ex_code_DX = `ECODE_ILLEGAL_INST;
	    new_ex_DX = 1;
	 end
      end
   end
   
   assign branch_taken = ((opcode == `RV32_BRANCH) && cmp_true) && !kill_DX;
   assign jal = (opcode == `RV32_JAL) && !kill_DX;
   assign jalr = (opcode == `RV32_JALR) && !kill_DX;

   assign redirect = branch_taken || jal || jalr;
   
   always @(*) begin
      if (exception) begin
         PC_src_sel = `PC_HANDLER;
      end else if (replay_IF) begin
	 PC_src_sel = `PC_REPLAY;
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
	`RV32_LUI : uses_rs1 = 1'b0;
	`RV32_AUIPC : uses_rs1 = 1'b0;
	`RV32_JAL : uses_rs1 = 1'b0;
	default : uses_rs1 = 1'b1;
      endcase // case (opcode)
   end // always @ begin

   always @(*) begin
      case (opcode)
	`RV32_OP : uses_rs2 = 1'b1;
	`RV32_BRANCH : uses_rs2 = 1'b1;
	`RV32_STORE : uses_rs2 = 1'b1;
	default : uses_rs2 = 1'b0;
      endcase // case (opcode)
   end // always @ begin

   
   always @(*) begin
      case (opcode)
        `RV32_LUI : src_a_sel = `SRC_A_ZERO;
        `RV32_AUIPC : src_a_sel = `SRC_A_PC;
        `RV32_JAL : src_a_sel = `SRC_A_PC;
        `RV32_JALR : src_a_sel = `SRC_A_PC;
        default : src_a_sel = `SRC_A_RS1;
      endcase // case (opcode)
   end // always @ begin

   always @(*) begin
      case (opcode)
        `RV32_JAL : src_b_sel = `SRC_B_FOUR;
        `RV32_JALR : src_b_sel = `SRC_B_FOUR;
        `RV32_BRANCH : src_b_sel = `SRC_B_RS2;
        `RV32_OP : src_b_sel = `SRC_B_RS2;
        default : src_b_sel = `SRC_B_IMM;
      endcase // case (opcode)
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

   always @(*) begin
      case (funct3)
        `RV32_FUNCT3_BEQ : alu_op_branch = `ALU_OP_SEQ;
        `RV32_FUNCT3_BNE : alu_op_branch = `ALU_OP_SNE;
        `RV32_FUNCT3_BLT : alu_op_branch = `ALU_OP_SLT;
        `RV32_FUNCT3_BGE : alu_op_branch = `ALU_OP_SGE;
        `RV32_FUNCT3_BLTU : alu_op_branch = `ALU_OP_SLTU;
        `RV32_FUNCT3_BGEU : alu_op_branch = `ALU_OP_SGEU;
        default : alu_op_branch = `ALU_OP_SEQ;
      endcase // case (funct3)
   end // always @ begin

   always @(*) begin
      case (opcode)
        `RV32_OP : alu_op = alu_op_arith;
        `RV32_OP_IMM : alu_op = alu_op_arith;
        `RV32_BRANCH : alu_op = alu_op_branch;
        default : alu_op = `ALU_OP_ADD;
      endcase // case (opcode)
   end // always @ begin
   //           
   assign reg_to_wr_DX = inst_DX[11:7];
   assign rs1_addr = inst_DX[19:15];
   assign rs2_addr = inst_DX[24:20];

   assign wb_src_sel_DX = (opcode == `RV32_LOAD) ? `WB_SRC_MEM : (csr_cmd != `CSR_IDLE) ? `WB_SRC_CSR : `WB_SRC_ALU;
   assign dmem_en = ((opcode == `RV32_LOAD) || (opcode == `RV32_STORE)) && !kill_DX;
   assign dmem_wen = (opcode == `RV32_STORE) && !kill_DX;
   assign dmem_size = funct3;


   // csr access decoding requires some well-chosen encodings
   // lower 2 bits of funct3 map directly to lower 2 bits of cmd on modify
   // top bit of cmd indicates access
   // top bit of funct3 indicates imm
   always @(*) begin
      csr_cmd = `CSR_IDLE;
      csr_imm_sel = funct3[2];
      if (opcode == `RV32_SYSTEM && funct3[1:0] != 2'b0) begin
	 csr_cmd = (inst_DX[19:15] == 5'b0) ? `CSR_READ : {1'b1,funct3[1:0]};
      end
   end // always @ begin

   always @(*) begin
      case (opcode)
	`RV32_LOAD     : illegal_opcode = 1'b0;
	`RV32_STORE    : illegal_opcode = 1'b0;
	`RV32_MADD     : illegal_opcode = 1'b0;
	`RV32_BRANCH   : illegal_opcode = 1'b0;
	`RV32_LOAD_FP  : illegal_opcode = 1'b0;
	`RV32_STORE_FP : illegal_opcode = 1'b0; 
	`RV32_MSUB     : illegal_opcode = 1'b0;
	`RV32_JALR     : illegal_opcode = 1'b0;
	`RV32_CUSTOM_0 : illegal_opcode = 1'b0;
	`RV32_CUSTOM_1 : illegal_opcode = 1'b0;
	`RV32_NMSUB    : illegal_opcode = 1'b0;
	`RV32_MISC_MEM : illegal_opcode = 1'b0;
	`RV32_AMO      : illegal_opcode = 1'b0;
	`RV32_NMADD    : illegal_opcode = 1'b0;
	`RV32_JAL      : illegal_opcode = 1'b0;
	`RV32_OP_IMM   : illegal_opcode = 1'b0;
	`RV32_OP       : illegal_opcode = 1'b0;
	`RV32_OP_FP    : illegal_opcode = 1'b0;
	`RV32_SYSTEM   : illegal_opcode = 1'b0;
	`RV32_AUIPC    : illegal_opcode = 1'b0;
	`RV32_LUI      : illegal_opcode = 1'b0;
	default : illegal_opcode = 1'b1;
	endcase // case (opcode)
   end // always @ begin
   

   // WB stage ctrl
   
   always @(posedge clk) begin
      if (reset || (kill_DX && !stall_WB)) begin
         wr_reg_unkilled_WB <= 0;
         had_ex_WB <= 0;
      end else if (!stall_WB) begin
         wr_reg_unkilled_WB <= wr_reg_DX;
         wb_src_sel_WB <= wb_src_sel_DX;
         had_ex_WB <= ex_DX;
	 prev_ex_code_WB <= ex_code_DX;
         reg_to_wr_WB <= reg_to_wr_DX;
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
	    ex_code_WB = `ECODE_LOAD_ADDR_MISALIGNED;
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
