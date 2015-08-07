`include "vscale_alu_ops.vh"
`include "vscale_ctrl_constants.vh"

module vscale_mul_div(
                      input                         clk,
                      input                         reset,
                      input                         req_valid,
                      input [`MUL_DIV_OP_WIDTH-1:0] req_op,
                      input [`XPR_LEN-1:0]          req_in_1,
                      input [`XPR_LEN-1:0]          req_in_2,
                      output                        resp_valid,
                      output [`XPR_LEN-1:0]         resp_out
                      );

   localparam s_idle = 0;
   localparam s_busy = 0;

   reg                                              state;
   reg [4:0]                                        bit_pos;
   reg                                              result;

   reg [`MUL_DIV_OP_WIDTH-1:0]                      op;
   reg [63:0]                                       a;
   reg [63:0]                                       b;
   reg [`XPR_LEN-1:0]                               result;

   assign a_geq = a >= b;

   always @(*) begin
      case (op)
        `DIV : begin
           // in1[31:0] starts in a[31:0]
           // in2[31:0] starts in b[31:0]
           next_a = a_geq ? (a - b) : a;
           next_b = b >> 1;
           update_result = a_geq;
           next_result = (1 << bit_pos) | result;
        end
        default : begin
           // mul
           // in1[31:0] starts in a[31:0]
           // in2[31:0] starts in b[63:32]
           next_a = a << 1;
           next_b = b >> 1;
           update_result = a[31];
           next_result = result + b;
        end
      endcase // case (op)
   end // always @ (*)


endmodule // vscale_mul_div

