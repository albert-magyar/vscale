`include "vscale_ctrl_constants.vh"

module vscale_src_a_mux(
                        input [2:0]       src_a_sel,
                        input [31:0]      PC_DX,
                        input [31:0]      rs1_data,
                        output reg [31:0] alu_src_a
                        );


   always @(*) begin
      case (src_a_sel)
        `SRC_A_RS1 : alu_src_a = rs1_data;
        `SRC_A_PC : alu_src_a = PC_DX;
        default : alu_src_a = 0;
      endcase // case (src_a_sel)
   end

endmodule // vscale_src_a_mux
