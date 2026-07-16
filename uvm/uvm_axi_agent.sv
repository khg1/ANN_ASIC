class uvm_axi_agent extends uvm_agent;
  `uvm_component_utils(uvm_axi_agent)
  
  uvm_axi_monitor monitor;
  uvm_axi_driver  driver;
  uvm_axi_sequencer sequencer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = uvm_axi_monitor::type_id::create("monitor", this);
    if(get_is_active() == UVM_ACTIVE) begin                               // active agent
      driver = uvm_axi_driver::type_id::create("driver", this);
      sequencer = uvm_axi_sequencer::type_id::create("sequencer", this);
    end
  endfunction
  
  function void connect_phase(uvm_phase phase);
    if(get_is_active() == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass
