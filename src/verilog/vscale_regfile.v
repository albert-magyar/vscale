module vscale_regfile(
		      clk,
		      ra1,
		      rd1,
		      ra2,
		      rd2,
		      wen,
		      wa,
		      wd
		      );

   reg [31:0] data [31:0];
   wire       wen_internal;

   // fpga-style zero register
   assign wen_internal = wen && |wa;

   assign rd1 = |ra1 ? data[ra1] : 0;
   assign rd2 = |ra2 ? data[ra2] : 0;

   always @(posedge clk) begin
      if (wen_internal) begin
	data[wa] <= wd;
      end
   end

endmodule // vscale_regfile

   
