`include "vscale_ctrl_constants.vh"
`include "vscale_csr_addr_map.vh"

module vscale_top(
		  input clk,
		  input reset
		  );

   wire 		resetn;
   
   wire [31:0] 		imem_haddr;
   wire 		imem_hwrite;
   wire [2:0] 		imem_hsize;
   wire [2:0] 		imem_hburst;
   wire 		imem_hmastlock;
   wire [3:0] 		imem_hprot;
   wire [1:0] 		imem_htrans;
   wire [31:0] 		imem_hwdata;
   wire [31:0] 		imem_hrdata;
   wire 		imem_hready;
   wire 		imem_hresp;
   
   wire [31:0] 		dmem_haddr;
   wire 		dmem_hwrite;
   wire [2:0] 		dmem_hsize;
   wire [2:0] 		dmem_hburst;
   wire 		dmem_hmastlock;
   wire [3:0] 		dmem_hprot;
   wire [1:0] 		dmem_htrans;
   wire [31:0] 		dmem_hwdata;
   wire [31:0] 		dmem_hrdata;
   wire 		dmem_hready;
   wire 		dmem_hresp;

   wire                 htif_reset;
   wire                 htif_pcr_req_valid;
   wire                 htif_pcr_req_ready;
   wire                 htif_pcr_req_rw;
   wire [`CSR_ADDR_WIDTH-1:0] htif_pcr_req_addr;
   wire [`HTIF_PCR_WIDTH-1:0] htif_pcr_req_data;
   wire                       htif_pcr_resp_valid;
   wire                       htif_pcr_resp_ready;
   wire [`HTIF_PCR_WIDTH-1:0] htif_pcr_resp_data;

   assign resetn = ~reset;

   assign htif_reset = reset;
   assign htif_pcr_req_valid = 1'b0;
   assign htif_pcr_req_rw = 1'b0;
   assign htif_pcr_req_addr = `CSR_ADDR_WIDTH'b0;
   assign htif_pcr_req_data = `HTIF_PCR_WIDTH'b0;
   assign htif_pcr_resp_ready = 1'b0;
   
   vscale_hasti_wrapper vscale(
			       .hclk(clk),
			       .hresetn(resetn),
			       .imem_haddr(imem_haddr),
			       .imem_hwrite(imem_hwrite),
			       .imem_hsize(imem_hsize),
			       .imem_hburst(imem_hburst),
			       .imem_hmastlock(imem_hmastlock),
			       .imem_hprot(imem_hprot),
			       .imem_htrans(imem_htrans),
			       .imem_hwdata(imem_hwdata),
			       .imem_hrdata(imem_hrdata),
			       .imem_hready(imem_hready),
			       .imem_hresp(imem_hresp),
			       .dmem_haddr(dmem_haddr),
			       .dmem_hwrite(dmem_hwrite),
			       .dmem_hsize(dmem_hsize),
			       .dmem_hburst(dmem_hburst),
			       .dmem_hmastlock(dmem_hmastlock),
			       .dmem_hprot(dmem_hprot),
			       .dmem_htrans(dmem_htrans),
			       .dmem_hwdata(dmem_hwdata),
			       .dmem_hrdata(dmem_hrdata),
			       .dmem_hready(dmem_hready),
			       .dmem_hresp(dmem_hresp),
			       .htif_reset(htif_reset),
			       .htif_pcr_req_valid(htif_pcr_req_valid),
			       .htif_pcr_req_ready(htif_pcr_req_ready),
			       .htif_pcr_req_rw(htif_pcr_req_rw),
			       .htif_pcr_req_addr(htif_pcr_req_addr),
			       .htif_pcr_req_data(htif_pcr_req_data),
			       .htif_pcr_resp_valid(htif_pcr_resp_valid),
			       .htif_pcr_resp_ready(htif_pcr_resp_ready),
			       .htif_pcr_resp_data(htif_pcr_resp_data)
			       );
   
   vscale_hasti_sram imem(
			  .hclk(clk),
			  .hresetn(resetn),
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
			  .hresp(imem_hresp)    
			  );

   vscale_hasti_sram dmem(
			  .hclk(clk),
			  .hresetn(resetn),
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
			  .hresp(dmem_hresp)    
			  );
      
endmodule // vscale_top
