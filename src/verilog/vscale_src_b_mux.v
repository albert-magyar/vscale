`include "vscale_ctrl_constants.vh"

module vscale_src_b_mux(
                        input [2:0]       src_b_sel,
                        input [31:0]      imm,
                        input [31:0]      rs2_data,
                        output reg [31:0] alu_src_b
                        );


   always @(*) begin
      case (src_b_sel)
        `SRC_B_RS2 : alu_src_b = rs2_data;
        `SRC_B_IMM : alu_src_b = imm;
        `SRC_B_FOUR : alu_src_b = 4;
        default : alu_src_b = 0;
      endcase // case (src_b_sel)
   end

endmodule // vscale_src_b_mux
