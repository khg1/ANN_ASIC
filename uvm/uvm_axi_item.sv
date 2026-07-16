class uvm_axi_item #(int ID_W = 1, int DATA_W = 32, int ADDR_W = 12) extends uvm_sequence_item;
  `uvm_object_utils(uvm_axi_item #(ID_W,DATA_W,ADDR_W))

  rand axi_op_e         op;             // operation type: READ or WRITE           
  rand logic [ADDR_W-1:0] addr;         // address for the AXI transaction 
  
  rand logic [7:0]        len;           
  rand logic [2:0]        size;         
  rand logic [1:0]        burst;     
  rand logic [ID_W-1:0]   id;

  logic      [1:0]       resp;
  rand logic [DATA_W-1:0] data_q[$];    // queue to hold data for burst transactions           

  // constraint to ensure that the data queue size matches the burst length for write transactions and is empty for read transactions
  constraint c_data_size {
    if (op == WRITE) {
      data_q.size() == (len + 1);
    } else {
      data_q.size() == 0; 
  }

  // constraint to ensure that the burst length is 4 beats
  constraint c_size {
    size == 3'b010;
  }

  // constraint to ensure that only INCR burst type is used
  constraint c_burst {
    burst == 2'b01; 
  }

  // constraint to ensure that addresses are aligned to 4 bytes
  constraint c_addr_align {
    addr[1:0] == 2'b00; 
  }

  function new(string name = "axi_item");
    super.new(name);
  endfunction


  function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_string("op", op.name());
    printer.print_int("addr", addr, $bits(addr), UVM_HEX);
    printer.print_int("len", len, $bits(len), UVM_DEC);

    foreach(data_q[i]) begin
      printer.print_int($sformatf("data[%0d]", i), data_q[i], 32, UVM_HEX);
    end
  endfunction

endclass
