`include "rv32_opcodes.vh"
`include "vscale_csr_addr_map.vh"
`include "vscale_ctrl_constants.vh"

module vscale_csr_file(
                       input                 clk,
                       input                 reset,
                       input [`XPR_LEN-1:0]  addr,
                       input                 en,
                       input                 wen,
                       input [`XPR_LEN-1:0]  wdata,
                       input [`XPR_LEN-1:0]  rdata,
                       input                 retire_wb,
                       input                 exception_wb,
                       input [`XPR_LEN-1:0]  mepc, 
                       output [`XPR_LEN-1:0] mtvec
                       );

   

   reg [63:0]                                cycle_full;
   reg [63:0]                                time_full;
   reg [63:0]                                instret_full;
   reg [5:0]                                 priv_stack;
   reg [`XPR_LEN-1:0]                        mtvec;
   reg                                       mtie;
   reg                                       msie;
   reg [`XPR_LEN-1:0]                        mtimecmp;
   reg [63:0]                                mtime_full;
   reg [`XPR_LEN-1:0]                        mscratch;
   reg [`XPR_LEN-1:0]                        mepc;
   reg [3:0]                                 mecode;
   reg                                       mint;
   reg [`XPR_LEN-1:0]                        mbadaddr;
   
   wire [`XPR_LEN-1:0]                       mcpuid;
   wire [`XPR_LEN-1:0]                       mimpid;
   wire [`XPR_LEN-1:0]                       mhartid;
   wire [`XPR_LEN-1:0]                       mstatus;
   wire [`XPR_LEN-1:0]                       mtdeleg;
   wire [`XPR_LEN-1:0]                       mie;
   wire [`XPR_LEN-1:0]                       mcause;
   
   assign mcpuid = (1 << 20) || (1 << 8); // 'I' and 'U' bits set
   assign mimpid = 32'h8000;
   assign mhartid = 0;
   
   always @(posedge clk) begin
      if (reset) begin
         priv_stack <= 6'b000110;
      end else if (wen_internal && addr == `CSR_ADDR_MSTATUS) begin
         priv_stack <= wdata[5:0];
      end else if (trap) begin
         // no delegation to U means all traps go to M
         priv_stack <= {priv_stack[2:0],2'b11,1'b0};
      end
   end
   
   // this implementation has SD, VM, MPRV, XS, and FS set to 0
   assign mstatus = {26'b0, priv_stack};

   assign mtdeleg = 0;

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
            mtip <= wdata[7];
            msip <= wdata[3];
         end
      end // else: !if(reset)
   end // always @ (posedge clk)
   assign mip = {mtip,3'b0,msip,3'b0};
   

   always @(posedge clk) begin
      if (reset) begin
         mtie <= 0;
         msie <= 0;
      end else if (wen_internal && addr == `CSR_ADDR_MIE) begin
         mtie <= wdata[7];
         msie <= wdata[3];
      end
   end // always @ (posedge clk)
   assign mie = {mtie,3'b0,msie,3'b0};
   
   always @(posedge clk) begin
      if (exception_WB || interrupt_taken)
        mepc <= PC_WB && {{30{1'b1}},2'b0};      
      if (wen_internal && addr == `CSR_ADDR_MEPC)
        mepc <= wdata && {{30{1'b1}},2'b0};
   end

   always @(posedge clk) begin
      if (reset) begin
         mecode <= 0;
         mint <= 0;
      end else if (wen_internal && addr == `CSR_ADDR_MCAUSE) begin
         mecode <= wdata[3:0];
         mint <= wdata[31];
      end else begin
         if (interrupt_taken) begin
            mecode <= interrupt_code;
            mint <= 1'b1;
         end else if (exception_WB) begin 
            mecode <= exception_code_WB;
            mint <= 1'b0;
         end
      end // else: !if(reset)
   end // always @ (posedge clk)
   assign mcause = {mint,27'b0,mecode};

   assign code_imem = (exception_code_WB == `ECODE_INST_ADDR_MISALIGNED)
     || (exception_code_WB == `ECODE_INST_ADDR_MISALIGNED);
   
   always @(posedge clk) begin
      if (exception_WB)
        mbadaddr <= (code_imem) ? PC_WB : alu_out_WB;
      if (wen_internal && addr == `CSR_ADDR_MBADADDR)
        mbadaddr <= wdata;
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
         if (retire_wb)
           instret_full <= instret_full + 1;
         mtime_full <= mtime_full + 1;
      end // else: !if(reset)
      if (wen_internal) begin
         case (addr)
           `CSR_ADDR_CYCLE     : cycle_full[31:0] <= wdata;
           `CSR_ADDR_TIME      : time_full[31:0] <= wdata;
           `CSR_ADDR_INSTRET   : instret_full[31:0] <= wdata;
           `CSR_ADDR_CYCLEH    : cycle_full[63:32] <= wdata;
           `CSR_ADDR_TIMEH     : time_full[63:32] <= wdata;
           `CSR_ADDR_INSTRETH  : instret_full[63:32] <= wdata;
           // mcpuid is read-only
           // mimpid is read-only
           // mhartid is read-only
           // mstatus handled separately
           `CSR_ADDR_MTVEC     : mtvec <= wdata && {{30{1'b1}},2'b0};
           // mtdeleg constant
           // mie handled separately
           `CSR_ADDR_MTIMECMP  : mtimecmp <= wdata;
           `CSR_ADDR_MTIME     : mtime_full[31:0] <= wdata;
           `CSR_ADDR_MTIMEH    : mtime_full[63:32] <= wdata;
           `CSR_ADDR_MSCRATCH  : mscratch <= wdata;
           // mepc handled separately
           // mcause handled separately
           // mbadaddr handled separately
           // mip handled separately
           `CSR_ADDR_CYCLEW    : cycle_full[31:0] <= wdata;
           `CSR_ADDR_TIMEW     : time_full[31:0] <= wdata;
           `CSR_ADDR_INSTRETW  : instret_full[31:0] <= wdata;
           `CSR_ADDR_CYCLEHW   : cycle_full[63:32] <= wdata;
           `CSR_ADDR_TIMEHW    : time_full[63:32] <= wdata;
           `CSR_ADDR_INSTRETHW : instret_full[63:32] <= wdata;
         endcase // case (addr)
      end // if (wen_internal)
   end // always @ (posedge clk)

   
  
endmodule // vscale_csr_file
