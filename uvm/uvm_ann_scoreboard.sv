class uvm_ann_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uvm_ann_scoreboard)

  uvm_analysis_imp #(uvm_axi_item, uvm_ann_scoreboard) item_export; 

  logic [1:0] target_q[$];          // Queue to hold expected target values for comparison
  int correct_prediction = 0;       // Counter for correct predictions (for accuracy calculation)
  
  logic [1:0] temp_target_mem [0:149];  // Temporary array to read target values from file (IRIS Target Memory)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_export = new("item_export", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    $readmemh("iris_target.mem", temp_target_mem); // load target values from file into temporary array
    
    // push the target values into the queue for later comparison
    foreach(temp_target_mem[i]) begin
      target_q.push_back(temp_target_mem[i]);
    end
  endfunction

  // write function is called by the monitor whenever a new AXI transaction item is available for checking
  function void write(uvm_axi_item item);
    if (item.op == READ) begin              // only verify read transactions since they return data that can be compared against targets
       verify_burst_transaction(item);      // call the verification function to compare the read data against expected targets
    end
  endfunction

  function void verify_burst_transaction(uvm_axi_item item);
    logic [1:0] expected;
    logic [1:0] actual;

    // loop through each beat in the burst transaction and compare the actual read data against the expected target values from the queue
    foreach(item.data_q[i]) begin
    
      if (target_q.size() == 0) begin
        `uvm_error("SCB", "More data received than targets available!")
        break;
      end

      expected = target_q.pop_front();
      actual   = item.data_q[i];

      if (actual == expected) begin
         correct_prediction++;
        `uvm_info("SCB", $sformatf("Beat %0d PASS: Got %0d", i, actual), UVM_LOW)
      end else begin
         `uvm_error("SCB", $sformatf("Beat %0d FAIL: Exp %0d, Got %0d", i, expected, actual))
      end
    end
  endfunction

  // report phase to print final accuracy after all transactions have been processed
  function void report_phase(uvm_phase phase);
    int accuracy;
    super.report_phase(phase);
    
    if (correct_prediction >= 0) begin
        accuracy = (correct_prediction * 100) / 150; 
        `uvm_info("SCB", $sformatf("Accuracy = %0d%%", accuracy), UVM_NONE)
    end
  endfunction

endclass
