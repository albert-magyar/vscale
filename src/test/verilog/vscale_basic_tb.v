`include "vscale_ctrl_constants.vh"
`include "vscale_csr_addr_map.vh"

module vscale_basic_tb();

   reg clk;
   reg reset;


   wire htif_pcr_resp_valid;
   wire [`HTIF_PCR_WIDTH-1:0] htif_pcr_resp_data;
 

   reg [255:0] 		      reason = 0;
   reg [1023:0] 	      loadmem = 0;
   reg [1023:0] 	      vpdfile = 0;
   reg [  63:0] 	      max_cycles = 2000;
   reg [  63:0] 	      trace_count = 0;
   integer 		      stderr = 32'h80000002;
   
   
   vscale_top DUT(
		  .clk(clk),
		  .reset(reset),
                  .htif_pcr_req_valid(1'b1),
                  .htif_pcr_req_ready(),
                  .htif_pcr_req_rw(1'b0),
                  .htif_pcr_req_addr(`CSR_ADDR_TO_HOST),
                  .htif_pcr_req_data(`HTIF_PCR_WIDTH'b0),
                  .htif_pcr_resp_valid(htif_pcr_resp_valid),
                  .htif_pcr_resp_ready(1'b1),
                  .htif_pcr_resp_data(htif_pcr_resp_data)
		  );

   initial begin
      clk = 0;
      reset = 1;
   end
   
   always #5 clk = !clk;

   initial begin
      $value$plusargs("loadmem=%s", loadmem);
      $value$plusargs("vpdfile=%s", vpdfile);
      $readmemb(loadmem, DUT.imem.mem);
      $vcdplusfile(vpdfile);
      $vcdpluson();
      $vcdplusmemon();
      #100 reset = 0;
   end // initial begin

   
   always @(posedge clk) begin
      $fdisplay(stderr,"Running cycle %d", trace_count);
      trace_count = trace_count + 1;
      if (max_cycles > 0 && trace_count > max_cycles) begin
	reason = "timeout";
      end
      if (!reset) begin
	 if (htif_pcr_resp_valid && htif_pcr_resp_data != 0) begin
	    if (htif_pcr_resp_data == 144) begin
	       $vcdplusclose;
	       $finish;
	    end else begin
               $sformat(reason, "tohost = %d", htif_pcr_resp_data >> 1);
	    end
	 end
      end
      if (reason) begin
	 $fdisplay(stderr, "*** FAILED *** (%s) after %d simulation cycles", reason, trace_count);
	 $vcdplusclose;
	 $finish;
      end
   end
   
endmodule // vscale_top_tb

