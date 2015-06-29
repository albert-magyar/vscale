`include "vscale_hasti_constants.vh"

module vscale_hasti_wrapper(
                            input         hclk,
                            input         hresetn,
                            output [31:0] imem_haddr,
                            output        imem_hwrite,
                            output [2:0]  imem_hsize,
                            output [2:0]  imem_hburst,
                            output        imem_hmastlock,
                            output [3:0]  imem_hprot,
                            output [1:0]  imem_htrans,
                            output [31:0] imem_hwdata,
                            input [31:0]  imem_hrdata,
                            input         imem_hready,
                            input         imem_hresp,
                            output [31:0] dmem_haddr,
                            output        dmem_hwrite,
                            output [2:0]  dmem_hsize,
                            output [2:0]  dmem_hburst,
                            output        dmem_hmastlock,
                            output [3:0]  dmem_hprot,
                            output [1:0]  dmem_htrans,
                            output [31:0] dmem_hwdata,
                            input [31:0]  dmem_hrdata,
                            input         dmem_hready,
                            input         dmem_hresp
                            );
   
   wire                                   reset = ~hresetn;
   
   wire                                   imem_wait;
   wire [31:0]                            imem_addr;
   wire [31:0]                            imem_rdata;
   wire                                   imem_badmem_e;
   wire                                   dmem_wait;
   wire                                   dmem_en;
   wire                                   dmem_wen;
   wire [2:0]                             dmem_size;
   wire [31:0]                            dmem_addr;
   wire [31:0]                            dmem_wdata_delayed;
   wire [31:0]                            dmem_rdata;
   wire                                   dmem_badmem_e;
   
   vscale_hasti_bridge imem_bridge(
                                   .hclk(hclk),
                                   .hresetn(hresetn),
                                   .haddr(imem_haddr),
                                   .hwrite(imem_hwrite),
                                   .hsize(imem_hsize),
                                   .hburst(imem_hburst),
                                   .hmastlock(imem_hmastlock),
                                   .hprot(imem_hprot),
                                   .htrans(imem_htrans),
                                   .hwdata(imem_hwdata),
                                   .hrdata(imem_hrdata),
                                   .hready(imem_hready),
                                   .hresp(imem_hresp),
                                   .core_mem_en(1),
                                   .core_mem_wen(0),
                                   .core_mem_size(`HASTI_SIZE_WORD),
                                   .core_mem_addr(imem_addr),
                                   .core_mem_wdata_delayed(0),
                                   .core_mem_rdata(imem_rdata),
                                   .core_mem_wait(imem_wait),
                                   .core_badmem_e(imem_badmem_e)
                                   );

   vscale_hasti_bridge dmem_bridge(
                                   .hclk(hclk),
                                   .hresetn(hresetn),
                                   .haddr(dmem_haddr),
                                   .hwrite(dmem_hwrite),
                                   .hsize(dmem_hsize),
                                   .hburst(dmem_hburst),
                                   .hmastlock(dmem_hmastlock),
                                   .hprot(dmem_hprot),
                                   .htrans(dmem_htrans),
                                   .hwdata(dmem_hwdata),
                                   .hrdata(dmem_hrdata),
                                   .hready(dmem_hready),
                                   .hresp(dmem_hresp),
                                   .core_mem_en(dmem_en),
                                   .core_mem_wen(dmem_wen),
                                   .core_mem_size(dmem_size),
                                   .core_mem_addr(dmem_addr),
                                   .core_mem_wdata_delayed(dmem_wdata_delayed),
                                   .core_mem_rdata(dmem_rdata),
                                   .core_mem_wait(dmem_wait),
                                   .core_badmem_e(dmem_badmem_e)
                                   );


   vscale_core core(
                    .clk(hclk),
                    .reset(reset),
                    .imem_wait(imem_wait),
                    .imem_addr(imem_addr),
                    .imem_rdata(imem_rdata),
                    .imem_badmem_e(imem_badmem_e),
                    .dmem_wait(dmem_wait),
                    .dmem_en(dmem_en),
                    .dmem_wen(dmem_wen),
                    .dmem_size(dmem_size),
                    .dmem_addr(dmem_addr),
                    .dmem_wdata_delayed(dmem_wdata_delayed),
                    .dmem_rdata(dmem_rdata),
                    .dmem_badmem_e(dmem_badmem_e)
                    );

endmodule // vscale_core

