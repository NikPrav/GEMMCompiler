import numpy as np


def tile_systolic_array(input_array, weight_array, R, C, input_dim, output_dim, buf_size, data_size):
    # Tiling the input and weight arrays, and returning a 1D output array
    # Returns the instruction set, and the expected output of the GEMM (for now)
    # input_array: 1D numpy array padded to mach R dimensions
    # weight_array: 1D numpy array padded to match C dimensions (stored as transposed)
    # R : Number of rows in the systolic array
    # C : Number of columns in the systolic array
    # input_dim : Dimensions of the input array
    # output_dim : Dimensions of the weight array (transposed)
    # value_size : Size of the buffer in the systolic array
    # data_size : Size of the data type in the systolic array


    # Check if the dimensions are correct
    assert input_dim[1] == output_dim[1], "Mismatched dimensions"

    # Initialize output array
    # storing values for sanity check
    output_array = np.zeros(input_dim[0] * output_dim[0])

    # Initializing the instruction array
    
    # Calculating number of columns per tile
    n_cols = int(buf_size / (R * data_size))
    n_rows = int(buf_size / (C * data_size))

    # Calculating the number of tiles per row
    n_tiles_per_row = int(input_dim[1] / n_cols)
    n_tiles_per_column = int(output_dim[1] / n_rows)

    # Tile the multiplication rowise for inputs
    for i_row in range(0, input_dim[0]//R):

            # Tile the multiplication columnwise for weights
            for i_col in range(0, output_dim[0]//C):
                # Tiling for buffer size
                # Initializing an empty systolic array
                output_tile = np.zeros((R, C))
                for i_tile in range(0, n_tiles_per_row):
                    # Get the current tile
                    # Load to buffer from mem
                    # LOAD INP_BUF i*R*input_dim[1] 
                    # Calculating the offset by consider the tiles before the current tile
                    # tiles in current row + tiles in previous rows
                    # loading rowise 
                    offset_tile_input = i_row*(input_dim[1])*R + i_tile*n_cols
                    offset_tile_weight = i_col*(output_dim[1])*C + i_tile*n_cols
                    input_tile = np.zeros((R,n_cols))
                    weight_tile = np.zeros((n_cols,C))

                    

                    # Loading the inputs rowwise
                    for i_row_tile in range(0, R):
                        # LOAD INP_BUF offset_tile + offset_row + memory_offset
                        offset_row = i_row_tile * n_cols * n_tiles_per_row
                        input_tile[i_row_tile, :] = input_array[offset_tile_input + offset_row:offset_tile_input + offset_row + n_cols]
                        # input_tile = input_tile.reshape((R, n_cols))

                        # LOAD WT_BUF offset_tile + offset_row + memory_offset
                        weight_tile[:, i_row_tile] = weight_array[offset_tile_weight + offset_row:offset_tile_weight + offset_row + n_cols].T
                        # weight_tile = weight_tile.reshape((n_cols, C)).T
                    
                    # Perform the multiplication
                    # GEMM
                    output_tile += np.matmul(input_tile, weight_tile) 

                # Drain the array 
                # DRAIN         

                # Store the result in the output array
                                    
                for i_row_tile in range(0, R):
                    # STR OP_BUF offset_tile + offset_row + memory_offset
                    offset_row = i_row_tile * C * output_dim[0]//C
                    offset_tile = i_row * C * R * output_dim[0]//C  + i_col * C
                    output_array[offset_tile + offset_row:offset_tile + offset_row + C] = output_tile[i_row_tile, :] 

                    # for k in range(output_tile.shape[0]):
                    

            

    return output_array


input_array = np.random.rand(6, 6)
weight_array = np.random.rand(6, 6)

input_array = np.arange(1,37).reshape(6,6)
weight_array = np.arange(1,37).reshape(6,6)


buf_size = 4 * 8
data_size = 8

R = 2
C = 2

print(np.matmul(input_array, weight_array))
print(tile_systolic_array(input_array.flatten(), weight_array.T.flatten(), R, C, input_array.shape, weight_array.shape,buf_size,data_size))

print(np.array_equal(np.matmul(input_array, weight_array).flatten(), tile_systolic_array(input_array.flatten(), weight_array.T.flatten(), R, C, input_array.shape, weight_array.shape,buf_size,data_size)))