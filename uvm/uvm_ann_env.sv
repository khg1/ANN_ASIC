class uvm_ann_env extends uvm_env;
  `uvm_component_utils(uvm_ann_env)
  
  uvm_axi_agent      agent;   // AXI Agent (Driver + Monitor)
  uvm_ann_scoreboard scb;     // Scoreboard to check AXI transactions against expected results

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

// build the environment by creating the agent and scoreboard
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = uvm_axi_agent::type_id::create("agent", this);
    scb   = uvm_ann_scoreboard::type_id::create("scb", this);
  endfunction

// connect the monitor's analysis port to the scoreboard's analysis export
  function void connect_phase(uvm_phase phase);
    agent.monitor.ap.connect(scb.item_export);
  endfunction
endclass
