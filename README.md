# ANN_ASIC

A small fixed-point artificial neural network (ANN) accelerator with an AXI4 slave interface, verified with a UVM testbench. The design classifies the IRIS dataset (150 samples, 4 features each) into 3 classes using a fully-connected 4-10-3 multilayer perceptron with hardcoded, pre-trained weights.

This repository was split from [NPU_ASIC](https://github.com/khg1/NPU_ASIC).

## Architecture

```
                 ┌─────────────────────────────────────────────┐
 AXI4 (100 MHz)  │ axi4_ann_sub                                │
 ───────────────►│  write FSM ──► mem[] ──┐                    │
      burst      │  read  FSM ◄─ mem_out[]│  system FSM        │
                 │                        ▼  (WAIT/PULL/PUSH)  │
                 │            ┌───────────────────┐            │
                 │            │ ann_core (400 MHz)│            │
                 │            │  CDC sync + input │            │
                 │            │  ┌─────────────┐  │            │
                 │            │  │ top_ann     │  │            │
                 │            │  │  sram (ROM) │  │            │
                 │            │  │  ann        │  │            │
                 │            │  │   10x hidden│  │            │
                 │            │  │    3x output│  │            │
                 │            │  └─────────────┘  │            │
                 │            └───────────────────┘            │
                 └─────────────────────────────────────────────┘
```

- **`rtl/ann_soc_axi.sv`** (`axi4_ann_sub`) — AXI4 slave supporting INCR bursts. Buffers the full dataset in an input memory, streams samples through the ANN core, and serves results from an output memory. Dual clock: 100 MHz AXI domain, 400 MHz core domain.
- **`rtl/ann_core.sv`** — clock-domain-crossing wrapper (2-stage synchronizer) that unpacks each 32-bit word into four 8-bit features.
- **`rtl/top_ann.sv`** — connects the weight ROM/scheduler to the neural network.
- **`rtl/sram.sv`** — read-only weight/bias storage plus an FSM that time-multiplexes parameters to the neuron layers (~19 core clocks per sample).
- **`rtl/ann.sv`** — network topology: 10 hidden neurons, 3 output neurons, argmax comparator producing the 2-bit class (1–3).
- **`rtl/ann_neuron.sv` / `rtl/ann_out_neuron.sv`** — MAC-based neurons. Hidden neurons quantize back to 8 bits with saturation and apply ReLU; output neurons keep the full 16-bit result for the final comparison.

All arithmetic is **Q8.4 signed fixed-point** (8-bit values, 4 fraction bits) with 16-bit accumulators.

## Verification

UVM 1.2 environment in `uvm/`, top module `top_tb.sv`:

| Component | Role |
|---|---|
| `uvm_ann_test` | runs the full-dataset burst test |
| `uvm_axi_seq` | one 150-beat burst write (dataset), then one 150-beat burst read (results) |
| `uvm_axi_driver` / `uvm_axi_monitor` / `uvm_axi_sequencer` / `uvm_axi_agent` | AXI4 burst agent |
| `uvm_ann_scoreboard` | compares each returned class against `iris_target.mem` and reports accuracy |

`uvm/iris_dataset.mem` holds the 150 IRIS samples as one Q8.4 feature byte per line; `uvm/iris_target.mem` holds the expected class (1–3) per sample. Mispredictions are logged as `UVM_INFO` (the model is not 100% accurate — see below); protocol problems are `UVM_ERROR`.

## Running the simulation

Requires Synopsys VCS (with UVM 1.2) and optionally Verdi. From `Simulation/`:

```sh
make            # compile + run
make compile    # compile only (coverage instrumentation enabled)
make run        # run simulation (copies the .mem data files next to simv)
make verdi      # open Verdi with KDB + coverage database
make clean      # remove all generated files
```

The scoreboard prints per-sample results and a final `Accuracy = N%` in the report phase. Logs go to `compile.log` / `sim.log`; coverage (line, cond, FSM, toggle, branch, assert) is collected into `simv.vdb`.

## Known limitations

- **Model accuracy is 56%.** A bit-exact software model of the RTL arithmetic reproduces the same result, so this is a property of the quantized weights in `sram.sv`, not an RTL or testbench bug. The class-1 output neuron's weights are nearly all negative (and several weights are clipped at 0x80/−128), so all 50 Setosa samples are misclassified as class 2. Restoring accuracy requires retraining/requantizing the weights.
- **Input-alignment race in `ann_core.sv`.** The input register follows `spi_data_out` unconditionally (the edge-detected load is commented out), so when a new sample's computation restarts on the earliest possible clock edge, its first MAC can consume feature 0 of the previous sample. On this dataset it flips only a handful of borderline predictions.
- The AXI slave is simplified: INCR bursts only, no write-strobe address checking, single outstanding transaction.
