`include "my_enum.sv"
package uvm_ann_pkg;
	import uvm_pkg::*;
	typedef enum bit {READ = 0, WRITE = 1} axi_op_e;
	`include "uvm_macros.svh"
	`include "uvm_axi_item.sv"
	`include "uvm_axi_seq.sv"
	`include "uvm_axi_driver.sv"
	`include "uvm_axi_monitor.sv"
	`include "uvm_axi_sequencer.sv"
	`include "uvm_axi_agent.sv"
	`include "uvm_ann_scoreboard.sv"
	`include "uvm_ann_env.sv"
	`include "uvm_ann_test.sv"
endpackage
