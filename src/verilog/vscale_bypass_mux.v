module vscale_bypass_mux (
				input [31:0] raddr,
				input [31:0] waddr,
				input wen,
				input [2:0] wsrc,
				input [31:0] regfile_data,
				input [31:0] wb_data,
				output [31:0] bypassed_data
				);
				
				wire bypass = (wsrc == WB_SRC_ALU) && wen && (raddr == waddr);
				assign bypassed_data = bypass ? wb_data : regfile_data;
				
				endmodule
				