module alu(
	   fn,
	   in1,
	   in2,
	   out,
	   sum_diff_out
	   );

   parameter XLEN = 32;
   
   input [`ALU_OP_WIDTH-1:0] op;
   input [XLEN-1:0] 	     in1;
   input [XLEN-1:0] 	     in2;
   output reg [XLEN-1:0]     out;
   output wire [XLEN-1:0]    sum_diff_out;

   wire [4:0] 		  shamt;
   
   
   sum_diff_out = is_sub ? in1-in2 : in1+in2;

   always @(*) begin
      case op
	`ALU_OP_ADD : out = sum_diff_out;
 	`ALU_OP_SL : out = in1 << shamt;
	`ALU_OP_XOR : out = in1 ^ in2;
	`ALU_OP_OR : out = in1 | in2;
	`ALU_OP_AND : out = in1 & in2;
	`ALU_OP_SR : out = in1 >> shamt;
	`ALU_OP_SEQ : out = in1 == in2;
	`ALU_OP_SNE : out = in1 != in2;
	`ALU_OP_SUB : out = sum_diff_out;
	`ALU_OP_SRA : out = in1 >>> shamt;
	`ALU_OP_SLT : out = $signed(in1) < $signed(in2);
	`ALU_OP_SGE : out = $signed(in1) >= $signed(in2);
	`ALU_OP_SLTU : out = in1 < in2;
	`ALU_OP_SGEU : out = in1 >= in2;
	default : out = 0;
      endcase // case op
   end
   
   
endmodule // alu
