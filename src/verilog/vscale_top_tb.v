module vscale_top_tb();

   reg clk;
   reg reset;


   vscale_top DUT(
		  .clk(clk),
		  .reset(reset)
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

