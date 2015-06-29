`include "vscale_alu_ops.vh"

module vscale_alu(
		  op,
		  in1,
		  in2,
		  out,
		  );

   parameter XLEN = 32;
   
   input [3:0] op;
   input [XLEN-1:0] 	     in1;
   input [XLEN-1:0] 	     in2;
   output reg [XLEN-1:0]     out;

   wire [4:0] 		  shamt;
   
   
   always @(*) begin
      case (op)
	`ALU_OP_ADD : out = in1 + in2;
 	`ALU_OP_SL : out = in1 << shamt;
	`ALU_OP_XOR : out = in1 ^ in2;
	`ALU_OP_OR : out = in1 | in2;
	`ALU_OP_AND : out = in1 & in2;
	`ALU_OP_SR : out = in1 >> shamt;
	`ALU_OP_SEQ : out = in1 == in2;
	`ALU_OP_SNE : out = in1 != in2;
	`ALU_OP_SUB : out = in1 - in2;
	`ALU_OP_SRA : out = in1 >>> shamt;
	`ALU_OP_SLT : out = $signed(in1) < $signed(in2);
	`ALU_OP_SGE : out = $signed(in1) >= $signed(in2);
	`ALU_OP_SLTU : out = in1 < in2;
	`ALU_OP_SGEU : out = in1 >= in2;
	default : out = 0;
      endcase // case op
   end
   
   
endmodule // vscale_alu
