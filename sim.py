from dataflow import dataflow

X = 9
Y = 9   

R = 3
S = 3

C = 1
K = 1

array_height = 3 
array_width = 3

dataflow = dataflow(X, Y, R, S, C, K, array_height, array_width)

print(dataflow.row_stationary())
print(dataflow.input_stationary())
print(dataflow.output_stationary())
print(dataflow.weight_stationary())