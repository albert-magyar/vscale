`include "rv32_opcodes.vh"
`include "vscale_csr_addr_map.vh"
`include "vscale_ctrl_constants.vh"

module vscale_csr_file(
                       input 			    clk,
		       input 			    reset,
		       input [`CSR_ADDR_WIDTH-1:0] 	    addr,
		       input [`CSR_CMD_WIDTH-1:0]   cmd,
		       input [`XPR_LEN-1:0] 	    wdata,
		       output reg [`XPR_LEN-1:0] 	    rdata,
		       input 			    retire,
		       input 			    exception,
		       input [`EXCEPTION_CODE_WIDTH-1:0] exception_code,
		       input [`XPR_LEN-1:0] exception_load_addr,
		       input [`XPR_LEN-1:0] 	    exception_PC,
		       output [`XPR_LEN-1:0] 	    handler_PC,

		       input 			    htif_reset,
		       input 			    htif_pcr_req_valid,
		       output 			    htif_pcr_req_ready,
		       input 			    htif_pcr_req_rw,
		       input [`CSR_ADDR_WIDTH-1:0]  htif_pcr_req_addr,
		       input [`HTIF_PCR_WIDTH-1:0]  htif_pcr_req_data,
		       output 			    htif_pcr_resp_valid,
		       input 			    htif_pcr_resp_ready,
		       output [`HTIF_PCR_WIDTH-1:0] htif_pcr_resp_data
		       );

   localparam HTIF_STATE_IDLE = 0;
   localparam HTIF_STATE_WAIT = 1;
   
   reg [`HTIF_PCR_WIDTH-1:0] 			    htif_resp_data;
   reg 						    htif_state;
   reg 						    htif_resp_data_en;
   reg 						    next_htif_state;
   
   reg [63:0] 					    cycle_full;
   reg [63:0] 					    time_full;
   reg [63:0] 					    instret_full;
   reg [5:0] 					    priv_stack;
   reg [`XPR_LEN-1:0] 				    mtvec;
   reg 						    mtie;
   reg 						    msie;
   reg mtip;
   reg msip;
   reg [`XPR_LEN-1:0] 				    mtimecmp;
   reg [63:0] 					    mtime_full;
   reg [`XPR_LEN-1:0] 				    mscratch;
   reg [`XPR_LEN-1:0] 				    mepc;
   reg [`EXCEPTION_CODE_WIDTH-1:0] 					    mecode;
   reg 						    mint;
   reg [`XPR_LEN-1:0] 				    mbadaddr;
   
   wire prv;
   wire ie;
   
   wire [`XPR_LEN-1:0] 				    mcpuid;
   wire [`XPR_LEN-1:0] 				    mimpid;
   wire [`XPR_LEN-1:0] 				    mhartid;
   wire [`XPR_LEN-1:0] 				    mstatus;
   wire [`XPR_LEN-1:0] 				    mtdeleg;
   wire [`XPR_LEN-1:0] 				    mie;
   wire [`XPR_LEN-1:0] mip;
   wire [`XPR_LEN-1:0] 				    mcause;
   
   wire timer_expired;
   
   reg wen_internal;
   reg defined;
   reg [`XPR_LEN-1:0] wdata_internal;
   reg trap;
   reg interrupt_taken;
   reg [`EXCEPTION_CODE_WIDTH-1:0] interrupt_code;
   
   assign handler_PC = mtvec + (prv << 5);
   
   assign prv = priv_stack[2:1];
   assign ie = priv_stack[0];
   
   // TODO: setup internal wen, internal wdata
   always @(*) begin
      wen_internal = 0;
      wdata_internal = wdata;
   end
   
   // TODO: setup trap,timer,  iterrupt taken lines
   always @(*) begin
      trap = 0;
      interrupt_taken = 0;
      interrupt_code = 0;
      end
      
   
   always @(posedge clk) begin
      if (htif_reset)
	htif_state <= HTIF_STATE_IDLE;
      else
	htif_state <= next_htif_state;
      if (htif_resp_data_en)
	htif_resp_data <= rdata;
   end

   always @(*) begin
      htif_resp_data_en = 1'b0;
      next_htif_state = htif_state;
      case (htif_state)
	HTIF_STATE_IDLE : begin
	   if (htif_pcr_req_valid) begin
	      htif_resp_data_en = 1'b1;
	      next_htif_state = HTIF_STATE_WAIT;
	   end
	end
	HTIF_STATE_WAIT : begin
	   if (htif_pcr_resp_ready) begin
	      next_htif_state = HTIF_STATE_IDLE;
	   end
	end
      endcase // case (htif_state)
   end // always @ begin

   assign htif_pcr_req_ready = (htif_state == HTIF_STATE_IDLE);
   assign htif_pcr_resp_valid = (htif_state == HTIF_STATE_WAIT);
   assign htif_pcr_resp_data = htif_resp_data;
   
   assign mcpuid = (1 << 20) || (1 << 8); // 'I' and 'U' bits set
   assign mimpid = 32'h8000;
   assign mhartid = 0;
   
   always @(posedge clk) begin
      if (reset) begin
         priv_stack <= 6'b000110;
      end else if (wen_internal && addr == `CSR_ADDR_MSTATUS) begin
         priv_stack <= wdata_internal[5:0];
      end else if (trap) begin
         // no delegation to U means all traps go to M
         priv_stack <= {priv_stack[2:0],2'b11,1'b0};
      end
   end
   
   // this implementation has SD, VM, MPRV, XS, and FS set to 0
   assign mstatus = {26'b0, priv_stack};

   assign mtdeleg = 0;

    assign timer_expired = (mtimecmp == mtime_full[31:0]);

   always @(posedge clk) begin
      if (reset) begin
         mtip <= 0;
         msip <= 0;
      end else begin 
         if (timer_expired)
           mtip <= 1;
         if (wen_internal && addr == `CSR_ADDR_MTIMECMP)
           mtip <= 0;
         if (wen_internal && addr == `CSR_ADDR_MIP) begin
            mtip <= wdata_internal[7];
            msip <= wdata_internal[3];
         end
      end // else: !if(reset)
   end // always @ (posedge clk)
   assign mip = {mtip,3'b0,msip,3'b0};
   

   always @(posedge clk) begin
      if (reset) begin
         mtie <= 0;
         msie <= 0;
      end else if (wen_internal && addr == `CSR_ADDR_MIE) begin
         mtie <= wdata_internal[7];
         msie <= wdata_internal[3];
      end
   end // always @ (posedge clk)
   assign mie = {mtie,3'b0,msie,3'b0};
   
   always @(posedge clk) begin
      if (exception || interrupt_taken)
        mepc <= exception_PC && {{30{1'b1}},2'b0};      
      if (wen_internal && addr == `CSR_ADDR_MEPC)
        mepc <= wdata_internal && {{30{1'b1}},2'b0};
   end

   always @(posedge clk) begin
      if (reset) begin
         mecode <= 0;
         mint <= 0;
      end else if (wen_internal && addr == `CSR_ADDR_MCAUSE) begin
         mecode <= wdata_internal[3:0];
         mint <= wdata_internal[31];
      end else begin
         if (interrupt_taken) begin
            mecode <= interrupt_code;
            mint <= 1'b1;
         end else if (exception) begin 
            mecode <= exception_code;
            mint <= 1'b0;
         end
      end // else: !if(reset)
   end // always @ (posedge clk)
   assign mcause = {mint,27'b0,mecode};

   assign code_imem = (exception_code == `ECODE_INST_ADDR_MISALIGNED)
     || (exception_code == `ECODE_INST_ADDR_MISALIGNED);
   
   always @(posedge clk) begin
      if (exception)
        mbadaddr <= (code_imem) ? exception_PC : exception_load_addr;
      if (wen_internal && addr == `CSR_ADDR_MBADADDR)
        mbadaddr <= wdata_internal;
   end    
   
   always @(*) begin
      case (addr)
        `CSR_ADDR_CYCLE     : begin rdata = cycle_full[31:0]; defined = 1'b1; end
        `CSR_ADDR_TIME      : begin rdata = time_full[31:0]; defined = 1'b1; end
        `CSR_ADDR_INSTRET   : begin rdata = instret_full[31:0]; defined = 1'b1; end
        `CSR_ADDR_CYCLEH    : begin rdata = cycle_full[63:32]; defined = 1'b1; end
        `CSR_ADDR_TIMEH     : begin rdata = time_full[63:32]; defined = 1'b1; end
        `CSR_ADDR_INSTRETH  : begin rdata = instret_full[63:32]; defined = 1'b1; end
        `CSR_ADDR_MCPUID    : begin rdata = mcpuid; defined = 1'b1; end
        `CSR_ADDR_MIMPID    : begin rdata = mimpid; defined = 1'b1; end
        `CSR_ADDR_MHARTID   : begin rdata = mhartid; defined = 1'b1; end
        `CSR_ADDR_MSTATUS   : begin rdata = mstatus; defined = 1'b1; end
        `CSR_ADDR_MTVEC     : begin rdata = mtvec; defined = 1'b1; end
        `CSR_ADDR_MTDELEG   : begin rdata = mtdeleg; defined = 1'b1; end
        `CSR_ADDR_MIE       : begin rdata = mie; defined = 1'b1; end
        `CSR_ADDR_MTIMECMP  : begin rdata = mtimecmp; defined = 1'b1; end
        `CSR_ADDR_MTIME     : begin rdata = mtime_full[31:0]; defined = 1'b1; end
        `CSR_ADDR_MTIMEH    : begin rdata = mtime_full[63:32]; defined = 1'b1; end
        `CSR_ADDR_MSCRATCH  : begin rdata = mscratch; defined = 1'b1; end
        `CSR_ADDR_MEPC      : begin rdata = mepc; defined = 1'b1; end
        `CSR_ADDR_MCAUSE    : begin rdata = mcause; defined = 1'b1; end
        `CSR_ADDR_MBADADDR  : begin rdata = mbadaddr; defined = 1'b1; end
        `CSR_ADDR_MIP       : begin rdata = mip; defined = 1'b1; end
        `CSR_ADDR_CYCLEW    : begin rdata = cycle_full[31:0]; defined = 1'b1; end
        `CSR_ADDR_TIMEW     : begin rdata = time_full[31:0]; defined = 1'b1; end
        `CSR_ADDR_INSTRETW  : begin rdata = instret_full[31:0]; defined = 1'b1; end
        `CSR_ADDR_CYCLEHW   : begin rdata = cycle_full[63:32]; defined = 1'b1; end
        `CSR_ADDR_TIMEHW    : begin rdata = time_full[63:32]; defined = 1'b1; end
        `CSR_ADDR_INSTRETHW : begin rdata = instret_full[63:32]; defined = 1'b1; end
        default : begin rdata = 0; defined = 1'b0; end
      endcase // case (addr)
   end // always @ (*)
   
   
   always @(posedge clk) begin
      if (reset) begin
         cycle_full <= 0;
         time_full <= 0;
         instret_full <= 0;
         mtime_full <= 0;
      end else begin
         cycle_full <= cycle_full + 1;
         time_full <= time_full + 1;
         if (retire)
           instret_full <= instret_full + 1;
         mtime_full <= mtime_full + 1;
      end // else: !if(reset)
      if (wen_internal) begin
         case (addr)
           `CSR_ADDR_CYCLE     : cycle_full[31:0] <= wdata_internal;
           `CSR_ADDR_TIME      : time_full[31:0] <= wdata_internal;
           `CSR_ADDR_INSTRET   : instret_full[31:0] <= wdata_internal;
           `CSR_ADDR_CYCLEH    : cycle_full[63:32] <= wdata_internal;
           `CSR_ADDR_TIMEH     : time_full[63:32] <= wdata_internal;
           `CSR_ADDR_INSTRETH  : instret_full[63:32] <= wdata_internal;
           // mcpuid is read-only
           // mimpid is read-only
           // mhartid is read-only
           // mstatus handled separately
           `CSR_ADDR_MTVEC     : mtvec <= wdata_internal && {{30{1'b1}},2'b0};
           // mtdeleg constant
           // mie handled separately
           `CSR_ADDR_MTIMECMP  : mtimecmp <= wdata_internal;
           `CSR_ADDR_MTIME     : mtime_full[31:0] <= wdata_internal;
           `CSR_ADDR_MTIMEH    : mtime_full[63:32] <= wdata_internal;
           `CSR_ADDR_MSCRATCH  : mscratch <= wdata_internal;
           // mepc handled separately
           // mcause handled separately
           // mbadaddr handled separately
           // mip handled separately
           `CSR_ADDR_CYCLEW    : cycle_full[31:0] <= wdata_internal;
           `CSR_ADDR_TIMEW     : time_full[31:0] <= wdata_internal;
           `CSR_ADDR_INSTRETW  : instret_full[31:0] <= wdata_internal;
           `CSR_ADDR_CYCLEHW   : cycle_full[63:32] <= wdata_internal;
           `CSR_ADDR_TIMEHW    : time_full[63:32] <= wdata_internal;
           `CSR_ADDR_INSTRETHW : instret_full[63:32] <= wdata_internal;
         endcase // case (addr)
      end // if (wen_internal)
   end // always @ (posedge clk)

   
  
endmodule // vscale_csr_file
