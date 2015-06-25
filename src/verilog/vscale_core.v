module vscale_core(
		   hclk,
		   hresetn
		   );

   wire reset;
   assign reset = ~hresetn;
   
   
   wire [31:0] PC_PIF;

   reg [31:0]  PC_IF;

   reg [31:0]  PC_DX;
   reg [31:0]  inst_DX;
   
   reg [31:0]  alu_out_WB;
   reg [31:0]  store_data_WB;
   reg [4:0]   reg_to_wr_WB;
   reg 	       wr_reg_WB;
   reg 	       wb_src_WB;
   
   wire        stall_IF;
   wire        stall_DX;
   wire        stall_WB;

   wire        PC_src_sel;
   wire        branch_cond_true;
   
   wire        imem_wait;
   wire [31:0] imem_addr;
   wire [31:0] imem_rdata;

   wire [2:0]  imm_type;
   wire [31:0] imm;
   
   wire        src_a_sel; // fix width
   wire        src_b_sel; // fix width
   
   wire [3:0]  alu_op;
   wire [31:0] alu_src_a;
   wire [31:0] alu_src_b;
   wire [31:0] alu_out;
   
   wire        dmem_wait;
   wire        dmem_en;
   wire        dmem_wen;
   wire [2:0]  dmem_size;
   wire [31:0] dmem_addr;
   wire [31:0] dmem_wdata_delayed;
   wire [31:0] dmem_rdata;
   
   always @(posedge hclk) begin
      if (reset) begin
	 PC_IF <= 0;
      end else if (~stall_IF) begin
	 PC_IF <= PC_PIF;	 
      end
   end
   
      
   always @(posedge hclk) begin
      if (reset) begin
	 inst_DX <= `RV_NOP;
      end else if (~stall_DX) begin
	 if (kill_IF) begin
	    inst_DX <= `RV_NOP;
	 end else begin
	    inst_DX <= imem_rdata;
	 end	 
      end
   end
   
   always @(posedge hclk) begin
      if (reset) begin
      end else if (~stall_WB) begin
	 if (kill_DX) begin
	 end else begin
	 end
      end
   end

   assign dmem_wdata_delayed = store_data_WB;
   
endmodule // vscale_core

