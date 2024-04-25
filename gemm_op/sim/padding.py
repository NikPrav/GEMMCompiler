import torch

def generate_weight_matrix(self, matrix_B, sys_params):
    # Pad the input matrices to match the systolic array dimensions
    # Flatten the matrices to 1D arrays

    # Calculate the number of tiles required
    # num_tiles_M = system_params.M // system_params.R + (1 if system_params.M % system_params.R != 0 else 0)
    num_tiles_K = matrix_B.shape[-1] // sys_params.C + (1 if matrix_B.shape[-2] % sys_params.C != 0 else 0)

    # Pad the last generated matrix with zeros if necessary
    # padded_M = num_tiles_M * system_params.R
    padded_K = num_tiles_K * sys_params.C

    # Pad matrices with zeros if necessary
    # padded_matrix_A = torch.nn.functional.pad(matrix_A, (0, 0, 0, padded_M - system_params.M))
    padded_matrix_B = torch.nn.functional.pad(matrix_B, (0, padded_K - sys_params.K, 0, 0))

    # Generate input matrices - these are before you account for buffer size
    # input_matrices_A_old = padded_matrix_A.split(system_params.R, dim=0)
    input_matrices_B_old = padded_matrix_B.split(sys_params.C, dim=1)

    # input_matrices_A = padded_matrix_A.flatten()
    input_matrices_B = padded_matrix_B.T.flatten()

    return input_matrices_B
    
def padding_func(l,system_params):
    input_weights = generate_weight_matrix(l.weights, system_params)
    l.weights = input_weights
    l.weight_size = input_weights.weight.size()

    # Updating new input size
    num_tiles_M = system_params.M // system_params.R + (1 if system_params.M % system_params.R != 0 else 0)
    num_tiles_N = system_params.N // (system_params.i_buf_size/(system_params.R*system_params.data_size)) + (1 if system_params.N % (system_params.i_buf_size/(system_params.R*system_params.data_size)) != 0 else 0)

    # Pad the last generated matrix with zeros if necessary
    M = num_tiles_M * system_params.R
    N = num_tiles_N * (system_params.i_buf_size/(system_params.R*system_params.data_size))
    l.input_size = (M, N)

    # l.output_size = l(x).size()