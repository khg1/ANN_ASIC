class uvm_ann_test extends uvm_test;
  `uvm_component_utils(uvm_ann_test)

  uvm_ann_env env;
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = uvm_ann_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    uvm_axi_seq seq;               // Sequence to generate AXI transactions for the test
    phase.raise_objection(this);   // Raise objection to prevent test from ending prematurely while the sequence is running
    seq = uvm_axi_seq::type_id::create("seq");
    `uvm_info("TEST", "Starting Full Dataset Burst Test...", UVM_LOW)
    seq.start(env.agent.sequencer);
    `uvm_info("TEST", "Test Complete", UVM_LOW)
    phase.drop_objection(this);   // Drop objection to allow test to end after sequence is done
  endtask

endclass
