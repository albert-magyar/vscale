`include "vscale_csr_addr_map.vh"

module vscale_top_tb();

   reg clk;
   reg reset;


   wire htif_pcr_resp_valid;
   wire htif_pcr_resp_data;
 
   
   vscale_top DUT(
		  .clk(clk),
		  .reset(reset)
                  .htif_pcr_req_valid(1'b0),
                  .htif_pcr_req_ready(),
                  .htif_pcr_req_rw(1'b0),
                  .htif_pcr_req_addr(`CSR_ADDR_TO_HOST),
                  .htif_pcr_req_data(0),
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

      $readmemb("vscale_simple_test.bin", DUT.imem.mem);
      
      $vcdplusfile ("vscale.vpd");
      $vcdpluson();
      $vcdplusmemon();

      #100 reset = 0;

      #2000 $finish;
      
   end

endmodule // vscale_top_tb

