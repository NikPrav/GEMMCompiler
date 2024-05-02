##This code generates sample input arrays for GEMM exceution check, can be loaded into the testbench code
import os
import numpy as np

M = 4
N = 4
K = 8

DATA_WIDTH = 16
FRAC_BITS = 4
INT_BITS = 4


def decimal_to_fixed_point_binary(number):
    fractional_bits = FRAC_BITS

    # Calculate the number of integer bits required to represent the given number of fractional bits
    integer_bits = INT_BITS

    # Ensure the number is within the representable range
    max_value = 2 ** (integer_bits - 1) - 2 ** (-fractional_bits)
    min_value = -(2 ** (integer_bits - 1))
    if number > max_value or number < min_value:
        print(number)
        raise ValueError("Number is out of the representable range")

    # Round the number to the nearest representable value
    scaled_number = round(number * (2**fractional_bits))

    # Convert the scaled integer part to binary
    integer_binary = bin(scaled_number & 0xFFFF)[2:].zfill(DATA_WIDTH)

    # Extract the integer and fractional parts
    integer_part = integer_binary[:-fractional_bits]
    fractional_part = integer_binary[-fractional_bits:]

    # Combine the integer and fractional parts with a decimal point
    fixed_point_binary = f"{integer_part}{fractional_part}"

    return fixed_point_binary


def convert_to_binary(number, width):
    """
    Converts an integer to a binary number of specified width.

    Args:
        number (int): The integer to convert.
        width (int): The desired width of the binary representation.

    Returns:
        str: Binary representation of the number with leading zeros to match the specified width.
    """
    binary = bin(number)[2:]  # Convert to binary and remove the '0b' prefix
    return binary.zfill(width)  # Add leading zeros to match the width


if os.path.exists("array_A_fi.txt"):
    os.remove("array_A_fi.txt")

if os.path.exists("array_B_fi.txt"):
    os.remove("array_B_fi.txt")

if os.path.exists("array_C_fi.txt"):
    os.remove("array_C_fi.txt")




# Custom input to the arrays 


B = np.array([[36, 47, 22,  3, 12,  8, 33, 21],
       [34, 42, 14, 33, 41, 35,  0, 29],
       [49, 16,  4, 47, 49, 12, 42, 42],
       [ 8, 48, 28,  1,  7, 36, 41, 14]])
A = np.array([[3799, 4419, 5296, 5449],
       [4549, 7859, 5867, 6447],
       [5637, 9566, 8223, 9169],
       [3426, 4143, 4289, 4675]])

# wmam = np.matmul(wm, am) = 
#                 [
#                     [ 101  225  349  473]
#                     [ 236  540  844 1148]
#                     [ 371  855 1339 1823]
#                     [ 506 1170 1834 2498]
#                 ]

# Randomly generate input arrays
#A = np.random.randint(50, size=(M,K))
print("A:")
print(repr(A))
print("\n")
#B = np.random.randint(50, size=(K,N))
B_T = np.transpose(B)
print("B:")
print(repr(B_T))
print("\n")

C = np.matmul(A, B)
print("C:")
print(repr(C))
print("\n")


A_flat = A.flatten(order="F")
A_list = A_flat.tolist()
A_bin = []

for item in A_list:
    temp = convert_to_binary(item, DATA_WIDTH)
    A_bin.append(temp)

B_flat = B.flatten()
B_list = B_flat.tolist()
B_bin = []

for x in B_list:
    temp = convert_to_binary(x, DATA_WIDTH)
    B_bin.append(temp)

C_flat = C.flatten(order="F")
C_list = C_flat.tolist()
C_bin = []

for x in C_list:
    temp = convert_to_binary(x, DATA_WIDTH)
    C_bin.append(temp)

file = open("array_A_fi.txt", "a")
for item in A_bin:
    file.write(str(item) + "\n")
file.close()

file = open("array_B_fi.txt", "a")
for item in B_bin:
    file.write(str(item) + "\n")
file.close()

file = open("array_C_fi.txt", "a")
for item in C_bin:
    file.write(str(item) + "\n")
file.close()
