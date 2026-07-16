class uvm_axi_driver extends uvm_driver #(uvm_axi_item);
  `uvm_component_utils(uvm_axi_driver)
  virtual axi_if vif;

  function new(string name = "axi_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    if(!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "No virtual interface found")
  endfunction

  task run_phase(uvm_phase phase);
    // Initialize AXI signals to default values
    vif.awvalid <= 0; vif.wvalid <= 0; vif.bready <= 0;
    vif.arvalid <= 0; vif.rready <= 0;

    forever begin
      seq_item_port.get_next_item(req);

      // Drive the AXI transaction based on the type of operation (read or write)
      if (req.op == WRITE) drive_write(req);
      else                 drive_read(req);
      
      seq_item_port.item_done();
    end
  endtask

  // task to drive AXI write transactions
  task drive_write(uvm_axi_item item);
    item.print();               // print the item for debugging purposes
    vif.awaddr  <= item.addr;
    vif.awlen   <= item.len;
    vif.awsize  <= 3'b010;      // 4 bytes
    vif.awburst <= item.burst;
    vif.awvalid <= 1;           // assert AWVALID to start the write address handshake
    
    do begin                    // wait for AWREADY from the DUT before deasserting AWVALID
      @(posedge vif.clk); 
    end while(!vif.awready);
    vif.awvalid <= 0;

    foreach(item.data_q[i]) begin       // loop through each beat in the burst and drive the corresponding WDATA, WSTRB, and WLAST signals
      vif.wdata  <= item.data_q[i];
      vif.wstrb  <= 4'b1111;
      vif.wlast  <= (i == item.len);
      vif.wvalid <= 1;
      do begin                        // wait for WREADY from the DUT before driving the next beat
        @(posedge vif.clk);
      end while(!vif.wready);
    end

    vif.wvalid <= 0;
    vif.wlast  <= 0;
    vif.bready <= 1;
    
    do begin                      // wait for BVALID from the DUT to get the write response
      @(posedge vif.clk);
    end while(!vif.bvalid);
    
    item.resp = vif.bresp;
    vif.bready <= 0;
  endtask

  // task to drive AXI read transactions
  task drive_read(uvm_axi_item item);
    vif.araddr  <= item.addr;
    vif.arlen   <= item.len;
    vif.arsize  <= 3'b010; 
    vif.arburst <= item.burst;
    vif.arvalid <= 1;

    do begin                        // wait for ARREADY from the DUT before deasserting ARVALID
      @(posedge vif.clk);
    end while(!vif.arready);

    vif.arvalid <= 0;             
    item.data_q.delete();         // clear any existing data in the item queue before collecting new read data
    vif.rready <= 1;
  
    forever begin
      @(posedge vif.clk);
      if(vif.rvalid && vif.rready) begin
        item.data_q.push_back(vif.rdata);
        if(vif.rlast) break;
      end
    end
    vif.rready <= 0;
  endtask

endclass
