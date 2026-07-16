`include "ann_neuron.sv"
`include "ann_out_neuron.sv"
`include "ann.sv"
`include "sram.sv"
`include "top_ann.sv"
`include "ann_core.sv"
`include "ann_soc_axi.sv"
`include "uvm_ann_pkg.sv"
`include "uvm_dpi_pkg.sv"
`include "axi_if.sv"

module top_tb;
  import uvm_pkg::*;
  import uvm_dpi_pkg::*;
  import uvm_ann_pkg::*;

  logic axi_clk = 0; // 100 MHz
  logic ann_clk = 0; // 400 MHz
  logic rst_n   = 0;
  
  always #5   axi_clk = ~axi_clk;   // 10ns Period
  always #1.25 ann_clk = ~ann_clk;  // 2.5ns Period

  // Instantiate the AXI interface
  axi_if intf(axi_clk, rst_n);

  // Instantiate the ANN SoC with AXI4 interface
  axi4_ann_sub dut (
    .clk(ann_clk),            // Fast Clock
    .S_AXI_ACLK(axi_clk),     // Slow Clock
    .S_AXI_ARESETN(rst_n),
    .S_AXI_AWID(intf.awid),
    .S_AXI_AWADDR(intf.awaddr),
    .S_AXI_AWLEN(intf.awlen),
    .S_AXI_AWSIZE(intf.awsize),
    .S_AXI_AWBURST(intf.awburst),
    .S_AXI_AWVALID(intf.awvalid),
    .S_AXI_AWREADY(intf.awready),
    .S_AXI_WDATA(intf.wdata),
    .S_AXI_WSTRB(intf.wstrb),
    .S_AXI_WLAST(intf.wlast),
    .S_AXI_WVALID(intf.wvalid),
    .S_AXI_WREADY(intf.wready),
    .S_AXI_BID(intf.bid),
    .S_AXI_BRESP(intf.bresp),
    .S_AXI_BVALID(intf.bvalid),
    .S_AXI_BREADY(intf.bready),
    .S_AXI_ARID(intf.arid),
    .S_AXI_ARADDR(intf.araddr),
    .S_AXI_ARLEN(intf.arlen),
    .S_AXI_ARSIZE(intf.arsize),
    .S_AXI_ARBURST(intf.arburst),
    .S_AXI_ARVALID(intf.arvalid),
    .S_AXI_ARREADY(intf.arready),
    .S_AXI_RID(intf.rid),
    .S_AXI_RDATA(intf.rdata),
    .S_AXI_RRESP(intf.rresp),
    .S_AXI_RLAST(intf.rlast),
    .S_AXI_RVALID(intf.rvalid),
    .S_AXI_RREADY(intf.rready)
  );

  // UVM Testbench
  initial begin
    uvm_config_db#(virtual axi_if)::set(null, "*", "vif", intf);  // Set the virtual interface for UVM components
    // Reset sequence
    rst_n = 0;
    repeat(10) @(posedge axi_clk);
    rst_n = 1;
  end

  // Run the UVM test
  initial begin
    run_test("uvm_ann_test");
  end

endmodule
