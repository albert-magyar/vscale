`include "vscale_alu_ops.vh"
`include "vscale_ctrl_constants.vh"

module vscale_mul_div(
		      input 			    clk,
		      input 			    reset,
		      input 			    req_valid,
		      input [`MUL_DIV_OP_WIDTH-1:0] req_op,
		      input [`XPR_LEN-1:0] 	    req_in_1,
		      input [`XPR_LEN-1:0] 	    req_in_2,
		      output 			    resp_valid,
		      output [`XPR_LEN-1:0] 	    resp_out
		      );

   localparam s_idle = 0;
   localparam s_busy = 0;

   reg 						    state;
   reg [4:0] 					    bit_pos;
   reg 						    result;
   
   reg [`MUL_DIV_OP_WIDTH-1:0] 			    op;
   reg [`XPR_LEN-1:0] 				    a;
   reg [`XPR_LEN-1:0] 				    b;
   
   
endmodule // vscale_mul_div

		      