class uvm_axi_monitor extends uvm_monitor;
  `uvm_component_utils(uvm_axi_monitor)
  
  virtual axi_if vif; 
  uvm_analysis_port #(uvm_axi_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    if(!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "No VIF")
  endfunction

  task run_phase(uvm_phase phase);
    fork                              // run separate tasks to monitor reads and writes concurrently
      monitor_writes();         
      monitor_reads();
    join
  endtask

  task monitor_writes();              
    logic [31:0] addr_q[$];           // queue to store incoming write addresses
    logic [31:0] data_buffer[$];      // buffer to accumulate write data beats
    
    forever @(posedge vif.clk) begin
      if (vif.awvalid && vif.awready) begin   // capture the write address when AWVALID and AWREADY handshake occurs
        addr_q.push_back(vif.awaddr);
      end
      if (vif.wvalid && vif.wready) begin     // capture the write data when WVALID and WREADY handshake occurs
        data_buffer.push_back(vif.wdata);
        if (vif.wlast) begin                 // package the collected address and data into an item and send it through the analysis port
          uvm_axi_item item = uvm_axi_item::type_id::create("item");
          item.op = WRITE;
          if (addr_q.size() > 0) begin
            item.addr = addr_q.pop_front();
          end else begin
            `uvm_error("MON", "Write Data received but no Write Address (AW) seen yet!")
            item.addr = 32'hBEEA_BEEA; 
          end
          item.data_q = data_buffer;
          ap.write(item);
          data_buffer.delete();
        end
      end
    end
  endtask


  task monitor_reads();
    logic [31:0] addr_q[$];      
    logic [31:0] data_buffer[$];  

    forever @(posedge vif.clk) begin
      if (vif.arvalid && vif.arready) begin
        addr_q.push_back(vif.araddr);
      end
      if (vif.rvalid && vif.rready) begin
        data_buffer.push_back(vif.rdata);
        if (vif.rlast) begin
          uvm_axi_item item = uvm_axi_item::type_id::create("item");
          item.op = READ;
          if (addr_q.size() > 0) begin
            item.addr = addr_q.pop_front();
          end else begin
             `uvm_error("MON", "Read Data received but no Read Address (AR) seen yet!")
             item.addr = 32'hBEEA_BEEA;
          end
          item.data_q = data_buffer;
          ap.write(item);
          data_buffer.delete();
        end
      end
    end
  endtask

endclass
