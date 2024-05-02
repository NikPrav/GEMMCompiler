import numpy as np

def systolic_array(input_array, weight_array, R, C, input_dim, output_dim):
    # Check if the dimensions are correct
    # assert input_dim[1] == output_dim[1], "Mismatched dimensions"

    # If input array columns do not match R, pad the array
    # if input_array.shape[1] % R != 0:
    #     padding = R - (input_array.shape[1] % R)
    #     input_array = np.pad(input_array, ((0,0), (0,padding)), 'constant')

    # # If weight array rows do not match C, pad the array
    # if weight_array.shape[0] % C != 0:
    #     padding = C - (weight_array.shape[0] % C)
    #     weight_array = np.pad(weight_array, ((0,padding), (0,0)), 'constant')

    # Initialize output array
    output_array = np.zeros(input_dim[0] * output_dim[0])

    

    # Tile the multiplication
    for i in range(0, input_dim[0]//R):
        for j in range(0, output_dim[0]//C):
            # Get the current tile
            # Load to buffer from mem
            # LOAD INP_BUF i*R*input_dim[1] + mem_offset
            input_tile = input_array[i*(R*input_dim[1]):(i+1)*(R*input_dim[1])]
            input_tile = input_tile.reshape((R, input_dim[1]))
            # LOAD WT_BUF j*C*output_dim[1] + mem_offset
            weight_tile = weight_array[j*(C*output_dim[1]):(j+1)*(C*output_dim[1])]
            weight_tile = weight_tile.reshape((output_dim[1], C)).T

            # weight_tile = weight_array[j:j+C, :]

            # Perform the multiplication
            # GEMM
            output_tile = np.matmul(input_tile, weight_tile.T)

            # Store the result in the output array
            # STORE OUT_BUF i*R*C + mem_offset row_offset_value
            for k in range(output_tile.shape[0]):
                output_array[i*R*C+k*C:i*R*C+(k+1)*C] = output_tile[k, :]

    return output_array


input_array = np.random.rand(16, 32)
weight_array = np.random.rand(8, 32)

R = 8
C = 8

print(np.matmul(input_array, weight_array.T))
print(systolic_array(input_array.flatten(), weight_array.T.flatten(), R, C, input_array.shape, weight_array.shape))

print(np.array_equal(np.matmul(input_array, weight_array.T).flatten(), systolic_array(input_array.flatten(), weight_array.T.flatten(), R, C, input_array.shape, weight_array.shape)))