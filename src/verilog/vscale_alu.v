`include "vscale_alu_ops.vh"

module vscale_alu(
                  input [3:0]       op,
                  input [31:0]      in1,
                  input [31:0]      in2,
                  output reg [31:0] out
                  );

   wire [4:0]                       shamt;
   
   assign shamt = in2[4:0];
   
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
