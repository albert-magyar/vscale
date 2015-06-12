module scratchpad(
		  input        clk,
		  input        reset,
		  input        bus_req_valid,
		  output       bus_req_ready,
		  input [31:0] bus_req_addr,
		  input        bus_req_wen,
		  input [3:0]  bus_req_wmask,
		  input [31:0] bus_req_data,
		  output       bus_resp_valid,
		  output       bus_resp_data,
		  input        cpu_i_req_valid,
		  output       cpu_i_req_ready,
		  input [31:0] cpu_i_req_addr,
		  output       cpu_i_resp_valid,
		  output       cpu_i_resp_data,
		  input        cpu_d_req_valid,
		  output       cpu_d_req_ready,
		  input [31:0] cpu_d_req_addr,
		  input        cpu_d_req_wen,
		  input [3:0]  cpu_d_req_wmask,
		  input [31:0] cpu_d_req_data,
		  input        cpu_d_req_tag,
		  output       cpu_d_resp_valid,
		  output       cpu_d_resp_data,
		  output       cpu_d_resp_tag
		  );

   parameter scratchpad_size_words = 1024;
   
   reg [31:0] 		       mem [scratchpad_size_words-1:0];

   wire 		       p0_from_bus;
   reg 			       bus_resp_valid;
   reg 			       cpu_i_resp_valid;
   reg 			       cpu_d_resp_valid;
   reg 			       cpu_d_resp_tag;
   
   // handle ready/valid logic for 3 ports
   assign bus_req_ready = 1'b1;
   assign p0_from_bus = bus_req_valid;
   assign cpu_d_req_ready = !p0_from_bus;
   assign cpu_i_req_ready = 1'b1;

   always @(posedge clk) begin
      bus_resp_valid <= bus_req_valid;
      cpu_i_resp_valid <= cpu_i_req_valid;
      cpu_d_resp_valid <= p0_from_bus ? 1'b0 : cpu_d_req_valid;
      cpu_d_resp_tag <= d_req_tag;
   end
   
   reg [31:0] 		       rd0;
   wire [31:0] 		       wd0;
   wire [3:0] 		       we0;
   wire [31:0] 		       addr0;

   reg [31:0] 		       rd1;
   reg [31:0] 		       addr1;


   always @(*) begin
      if (p0_from_bus) begin
	 wd0 = cpu_d_req_data;
	 we0 = cpu_d_req_wen ? cpu_d_req_wmask : 0;
	 addr0 = cpu_d_req_addr;
      end else begin
	 wd0 = bus_req_data;
	 we0 = bus_req_wen ? bus_req_wmask : 0;
	 addr0 = bus_req_addr;
      end
   end
      
   assign cpu_d_resp_data = rd0;
   assign bus_resp_data = rd0;

   assign addr1 = cpu_i_req_addr;
   assign cpu_i_resp_data = rd1;
   
   
   always @(posedge clk) begin
      rd0 <= mem[addr0];
      rd1 <= mem[addr1];
   end
   
   generate
      genvar i;
      for (i = 0; i < 4; i = i+1) begin
	 always @(posedge clk) begin
	    if (we0[i])
	      mem[addr0][i*8+:8] <= wd0[i*8+:8];	
	 end
      end
   endgenerate
   
endmodule // scratchpad
