module vscale_top_tb();

   reg clk = 0;
   reg reset = 1;

   vscale_top DUT(
		  .clk(clk),
		  .reset(reset)
		  );

   always #0.5 clk = !clk;

   initial begin
      
      $vcdplusfile ("vscale.vpd");
      $vcdpluson();

      @(posedge clk);
      @(posedge clk);

      reset = 0;

      $finish;
   end

endmodule // vscale_top_tb

