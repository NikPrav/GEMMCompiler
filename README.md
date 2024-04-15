# Demse Systolic Array (SA)
This SA is designed to support both Weights Stationary (WS) and Output Stationary (OS)

Each PE takes 2 bit control: 
- the top control: 1 bit indicates whether we put the top input stationary inside the local register of PE.
- the left control: 1 bit indicates whether we enable the calculation inside the PE.


## Instantiate the design at different levels
- systolic_array_datapath.v is pure computation datapath of systolic array supporting both weights stationary and output stationary, which could be used separately for **synthesis** and **PnR** purpose.

