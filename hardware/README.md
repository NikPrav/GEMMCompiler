# Dense Systolic Array (SA) for an End-to-end ML Accelerator Framework
The major components in this project include:

<img title="System architecture" alt=" " src="/hardware/hardware backend.png">

*  PE Grid (Datapath): Consists of all the MAC units that perform the GEMM operation on input data streams received from neighboring PEs (left and top) through ports in Output Stationary dataflow. 

* Controller: Manages the state transitions and flow of data through the systolic array.

* SRAM Banks: Three SRAM buffers for storing inputs,
weights, and outputs. Each PE continuously computes
and accumulates its output value, which is immediately
stored in the down buffer and remains stationary
for the duration of the computation.
    – The left buffer stores the input activation values
that flow horizontally across the systolic array.
This data feeds into the leftmost column of processing
elements (PEs) and moves to the right across
each row.
    – The top buffer holds the input weight values that
flow and accumulate vertically through the systolic
array. This data is provided to the topmost
row of PEs and travels downward through each
column.
    – As data flows through the systolic array (activations
from left to right and weights from top to
bottom), each PE multiplies its current input activation
with the current weight and accumulates
the result into its output value. The output value
is then held stationary in the down buffer.

* Instruction Reader: The instruction reader implements
a state machine to control the execution flow based
on the current opcode and internal state variables. It extracts
opcode, buffer ID, and memory location from the memory
snapshot (compiler output). Based on the opcode, the module
executes different operations such as loading data into
buffers (opcode_LD), performing matrix multiplication (opcode_
GEMM), or draining data from the systolic array (opcode_
DRAINSYS). 

* Wrapper (testbench): systolic_array_tb wraps around the systolic array
top module which provides the necessary data
and control signals while observing the output data.
More importantly, the wrapper acts as a state machine
for the unit, where each instruction corresponds to a
controller state and is set by the wrapper accordingly.

**NOTE:** The sizes of all the elements in the datapath (PE grid dimensions, SRAM buffer size, data width) are parameterized.
To simulate this code, use systolic_array_tb.v as the testbench, and store the instructions and data from the compiler in inst.txt and data.txt respectively. Results and inputs are dumped to output_buf.txt for further use. 

* FPGA Synthesis Results: 212 ALMs,344 ALUTs, 204
registers
* Fastest Clock (Intel DE10): 180 MHz across 4 TV corners
