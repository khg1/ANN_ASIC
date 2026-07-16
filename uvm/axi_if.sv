/*
  * UVM AXI4 Interface
  *
  * This interface defines the signals for an AXI4 interface, including
  * the write address channel, write data channel, write response channel,
  * read address channel, and read data channel.
  *
*/

interface axi_if(input logic clk, input logic rst_n);

  parameter int ID_W   = 1;
  parameter int DATA_W = 32;
  parameter int ADDR_W = 12;

  // write address channel
  logic [ID_W-1:0]   awid;
  logic [ADDR_W-1:0] awaddr;
  logic [7:0]        awlen;
  logic [2:0]        awsize;
  logic [1:0]        awburst;
  logic              awvalid;
  logic              awready;

  // write data channel
  logic [DATA_W-1:0]        wdata;
  logic [(DATA_W/8)-1:0]    wstrb;
  logic                     wlast;
  logic                     wvalid;
  logic                     wready;

  // write response channel
  logic [ID_W-1:0]   bid;
  logic [1:0]        bresp;
  logic              bvalid;
  logic              bready;

  // read address channel
  logic [ID_W-1:0]   arid;
  logic [ADDR_W-1:0] araddr;
  logic [7:0]        arlen;
  logic [2:0]        arsize;
  logic [1:0]        arburst;
  logic              arvalid;
  logic              arready;

  // read data channel
  logic [ID_W-1:0]   rid;
  logic [DATA_W-1:0] rdata;
  logic [1:0]        rresp;
  logic              rlast;
  logic              rvalid;
  logic              rready;

endinterface
