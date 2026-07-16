class uvm_axi_sequencer extends uvm_sequencer #(uvm_axi_item);
  
  `uvm_component_utils(uvm_axi_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass
