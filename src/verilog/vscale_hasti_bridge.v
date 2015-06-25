`include "vscale_hasti_constants.vh"

module vscale_hasti_bridge(
			   input 	 hclk,
			   input 	 hresetn,
			   output [31:0] haddr,
			   output 	 hwrite,
			   output [2:0]  hsize,
			   output [2:0]  hburst,
			   output 	 hmastlock,
			   output [3:0]  hprot,
			   output [1:0]  htrans,
			   output [31:0] hwdata,
			   input [31:0]  hrdata,
			   input 	 hready,
			   input 	 hresp,
			   input 	 core_mem_en,
 			   input 	 core_mem_wen,
			   input [2:0] 	 core_mem_size,
			   input [31:0]  core_mem_addr,
			   input [31:0]  core_mem_wdata_delayed,
			   output [31:0] core_mem_rdata,
			   output 	 core_mem_wait,
			   output 	 core_badmem_e
			   );
      

   assign haddr = core_mem_addr;
   assign hwrite = core_mem_en && core_mem_wen;
   assign hsize = core_mem_size;
   assign hburst = `HASTI_BURST_SINGLE;
   assign hmastlock = `HASTI_MASTER_NO_LOCK;
   assign hprot = 0; // possibly change
   assign htrans = core_mem_en ? `HASTI_NONSEQ : `HASTI_IDLE;
   assign hwdata = core_mem_wdata_delayed;
   assign core_mem_rdata = hrdata;
   assign core_mem_wait = ~hready;
   assign core_badmem_e = hresp == `HASTI_RESP_ERROR;

endmodule // vscale_hasti_bridge

