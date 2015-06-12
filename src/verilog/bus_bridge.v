		  module bus_bridge(
				    // Global Clock Signal
				    input wire 				      S_AXI_ACLK,
				    // Global Reset Signal. This Signal is Active LOW
				    input wire 				      S_AXI_ARESETN,
				    // Write address (issued by master, acceped by Slave)
				    input wire [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR,
				    // Write channel Protection type. This signal indicates the
				    // privilege and security level of the transaction, and whether
				    // the transaction is a data access or an instruction access.
				    input wire [2 : 0] 			      S_AXI_AWPROT,
				    // Write address valid. This signal indicates that the master signaling
				    // valid write address and control information.
				    input wire 				      S_AXI_AWVALID,
				    // Write address ready. This signal indicates that the slave is ready
				    // to accept an address and associated control signals.
				    output wire 			      S_AXI_AWREADY,
				    // Write data (issued by master, acceped by Slave)
				    input wire [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_WDATA,
				    // Write strobes. This signal indicates which byte lanes hold
				    // valid data. There is one write strobe bit for each eight
				    // bits of the write data bus.
				    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
				    // Write valid. This signal indicates that valid write
				    // data and strobes are available.
				    input wire 				      S_AXI_WVALID,
				    // Write ready. This signal indicates that the slave
				    // can accept the write data.
				    output wire 			      S_AXI_WREADY,
				    // Write response. This signal indicates the status
				    // of the write transaction.
				    output wire [1 : 0] 		      S_AXI_BRESP,
				    // Write response valid. This signal indicates that the channel
				    // is signaling a valid write response.
				    output wire 			      S_AXI_BVALID,
				    // Response ready. This signal indicates that the master
				    // can accept a write response.
				    input wire 				      S_AXI_BREADY,
				    // Read address (issued by master, acceped by Slave)
				    input wire [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR,
				    // Protection type. This signal indicates the privilege
				    // and security level of the transaction, and whether the
				    // transaction is a data access or an instruction access.
				    input wire [2 : 0] 			      S_AXI_ARPROT,
				    // Read address valid. This signal indicates that the channel
				    // is signaling valid read address and control information.
				    input wire 				      S_AXI_ARVALID,
				    // Read address ready. This signal indicates that the slave is
				    // ready to accept an address and associated control signals.
				    output wire 			      S_AXI_ARREADY,
				    // Read data (issued by slave)
				    output wire [C_S_AXI_DATA_WIDTH-1 : 0]    S_AXI_RDATA,
				    // Read response. This signal indicates the status of the
				    // read transfer.
				    output wire [1 : 0] 		      S_AXI_RRESP,
				    // Read valid. This signal indicates that the channel is
				    // signaling the required read data.
				    output wire 			      S_AXI_RVALID,
				    // Read ready. This signal indicates that the master can
				    // accept the read data and response information.
				    input wire 				      S_AXI_RREADY
				    output 				      bus_req_valid,
				    input 				      bus_req_ready,
				    output [31:0] 			      bus_req_addr,
				    output 				      bus_req_wen,
				    output [3:0] 			      bus_req_wmask,
				    output [31:0] 			      bus_req_data,
				    input 				      bus_resp_valid,
				    input 				      bus_resp_data
				    );


   localparam s_idle = 0;
   localparam s_have_waddr = 1;
   localparam s_have_req = 2;
   localparam s_get_resp = 3;
   localparam s_have_resp = 4;
   
   reg [1:0] 								      state;
   reg [1:0] 								      next_state;
   
   reg [31:0] 								      req_addr;
   reg [31:0] 								      req_data;
   reg [3:0] 								      req_wmask;
   reg 									      req_wen;

   reg 									      resp_data;
   
   always @(posedge S_AXI_ACLK) begin
      if (!S_AXI_ARESETN)
	state <= s_idle;
      else
	state <= next_state;
   end

   always @(posedge S_AXI_ACLK) begin
      if (state == s_idle && S_AXI_AWVALID)
	req_addr <= S_AXI_AWADDR;
      if (state == s_idle && S_AXI_ARVALID)
	req_addr <= S_AXI_ARADDR;
      if (state == s_have_waddr && S_AXI_WVALID) begin
	 req_data <= S_AXI_WDATA;
	 req_wmask <= S_AXI_WSTRB;
	 req_wen <= 1;
      end
   end // always @ (posedge S_AXI_ACLK)

   always @(posedge S_AXI_ACLK) begin
      if (state == s_get_resp && bus_resp_valid)
	resp_data <= bus_resp_data;
   end
   

   always @(posedge S_AXI_ACLK) begin 

   always @(*) begin
      
   end
   
   
endmodule // bus_bridge
