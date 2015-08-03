`include "vscale_ctrl_constants.vh"
`include "vscale_csr_addr_map.vh"

module zscale_top(
		  input 		       clk,
		  input 		       reset,
                  input 		       htif_pcr_req_valid,
                  output 		       htif_pcr_req_ready,
                  input 		       htif_pcr_req_rw,
                  input [`CSR_ADDR_WIDTH-1:0]  htif_pcr_req_addr,
                  input [`HTIF_PCR_WIDTH-1:0]  htif_pcr_req_data,
                  output 		       htif_pcr_resp_valid,
                  input 		       htif_pcr_resp_ready,
                  output [`HTIF_PCR_WIDTH-1:0] htif_pcr_resp_data
		  );

   wire                                      resetn;
   
   wire [31:0]                               imem_haddr;
   wire                                      imem_hwrite;
   wire [2:0]                                imem_hsize;
   wire [2:0]                                imem_hburst;
   wire                                      imem_hmastlock;
   wire [3:0]                                imem_hprot;
   wire [1:0]                                imem_htrans;
   wire [31:0]                               imem_hwdata = 0;
   wire [31:0]                               imem_hrdata;
   wire                                      imem_hready;
   wire                                      imem_hresp;
   
   wire [31:0]                               dmem_haddr;
   wire                                      dmem_hwrite;
   wire [2:0]                                dmem_hsize;
   wire [2:0]                                dmem_hburst;
   wire                                      dmem_hmastlock;
   wire [3:0]                                dmem_hprot;
   wire [1:0]                                dmem_htrans;
   wire [31:0]                               dmem_hwdata;
   wire [31:0]                               dmem_hrdata;
   wire                                      dmem_hready;
   wire                                      dmem_hresp;

   wire                                      htif_reset;
   
   assign resetn = ~reset;
   assign htif_reset = reset;
   
   ZscaleCore zscale(
		     .clk(clk),
                     .reset(reset),
		     .io_imem_haddr(imem_haddr),
		     .io_imem_hwrite(imem_hwrite),
		     .io_imem_hsize(imem_hsize),
		     .io_imem_hburst(imem_hburst),
		     .io_imem_hmastlock(imem_hmastlock),
		     .io_imem_hprot(imem_hprot),
		     .io_imem_htrans(imem_htrans),
		     .io_imem_hrdata(imem_hrdata),
		     .io_imem_hready(imem_hready),
		     .io_imem_hresp(imem_hresp),
		     .io_dmem_haddr(dmem_haddr),
		     .io_dmem_hwrite(dmem_hwrite),
		     .io_dmem_hsize(dmem_hsize),
		     .io_dmem_hburst(dmem_hburst),
		     .io_dmem_hmastlock(dmem_hmastlock),
		     .io_dmem_hprot(dmem_hprot),
		     .io_dmem_htrans(dmem_htrans),
		     .io_dmem_hwdata(dmem_hwdata),
		     .io_dmem_hrdata(dmem_hrdata),
		     .io_dmem_hready(dmem_hready),
		     .io_dmem_hresp(dmem_hresp),
		     .io_host_reset(htif_reset),
		     .io_host_id(1'b0),
		     .io_host_pcr_req_valid(htif_pcr_req_valid),
		     .io_host_pcr_req_ready(htif_pcr_req_ready),
		     .io_host_pcr_req_bits_rw(htif_pcr_req_rw),
		     .io_host_pcr_req_bits_addr(htif_pcr_req_addr),
		     .io_host_pcr_req_bits_data(htif_pcr_req_data),
		     .io_host_pcr_rep_valid(htif_pcr_resp_valid),
		     .io_host_pcr_rep_ready(htif_pcr_resp_ready),
		     .io_host_pcr_rep_bits(htif_pcr_resp_data),
		     .io_host_ipi_req_ready(1'b0),
		     .io_host_ipi_req_valid(),
		     .io_host_ipi_req_bits(),
		     .io_host_ipi_rep_ready(),
		     .io_host_ipi_rep_valid(1'b0),
		     .io_host_ipi_rep_bits(1'b0),
		     .io_host_debug_stats_pcr()
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
