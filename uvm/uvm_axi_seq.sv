class uvm_axi_seq extends uvm_sequence #(uvm_axi_item);
  `uvm_object_utils(uvm_axi_seq)

  int LEN_DATASET = 150;
  logic [7:0] dataset_mem [0:149][0:3]; 

  function new(string name="ann_burst_seq");
    super.new(name);
  endfunction

  task body();
    uvm_axi_item req;
    logic [31:0] packed_data;
    $readmemh("iris_dataset.mem", dataset_mem);      // load the 150 samples of the IRIS dataset from the file into a 2D array
    `uvm_info("SEQ", "Loaded iris_data.mem for Burst Transfer", UVM_LOW)
    req = uvm_axi_item#()::type_id::create("req");

    start_item(req);
    req.op    = WRITE;
    req.addr  = 32'h00;          // Start Address
    req.len   = LEN_DATASET - 1; 
    req.burst = 2'b01;           // INCR Burst
    // pack each sample 4 features into a single 32-bit word
    for (int i = 0; i < LEN_DATASET; i++) begin
      packed_data = {dataset_mem[i][0], dataset_mem[i][1], dataset_mem[i][2], dataset_mem[i][3]};
      req.data_q.push_back(packed_data);
    end
    finish_item(req);
    `uvm_info("SEQ", "Burst Write of 150 samples COMPLETE", UVM_LOW)

    #5000ns;  // Wait some time before issuing the read transaction to allow the DUT to process the write
    
    req = uvm_axi_item#()::type_id::create("req");
    start_item(req);
    req.op    = READ;
    req.addr  = 32'h00;       
    req.len   = LEN_DATASET - 1; 
    req.burst = 2'b01;        
    finish_item(req);
    `uvm_info("SEQ", "Burst Read of 150 results COMPLETE", UVM_LOW)
  endtask
endclass
