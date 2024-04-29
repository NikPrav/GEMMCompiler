import os
import numpy as np

M = 4
N = 4
K = 4

DATA_WIDTH = 8
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


# Randomly generate input arrays
A = np.random.randint(50, size=(M,N))
B = np.random.randint(50, size=(N,K))

# Custom input to the arrays 


# B = np.array([ [  1,  5, 10, 15],
#                 [  1, 20, 25, 30],
#                                 [  1, 35, 40, 45],
#                                 [  1, 50, 55, 60]])
# A = np.array([ [  1,  5,  9, 13],
#                                 [  2,  6, 10, 14],
#                                 [  3,  7, 11, 15],
#                                 [  4,  8, 12, 16]])

# wmam = np.matmul(wm, am) = 
#                 [
#                     [ 101  225  349  473]
#                     [ 236  540  844 1148]
#                     [ 371  855 1339 1823]
#                     [ 506 1170 1834 2498]
#                 ]
C = np.matmul(A, B)
print(C)


A_flat = A.flatten(order="F")
A_list = A_flat.tolist()
A_bin = []

for item in A_list:
    temp = convert_to_binary(item, 16)
    A_bin.append(temp)

B_flat = B.flatten()
B_list = B_flat.tolist()
B_bin = []

for x in B_list:
    temp = convert_to_binary(x, 16)
    B_bin.append(temp)

C_flat = C.flatten(order="F")
C_list = C_flat.tolist()
C_bin = []

for x in C_list:
    temp = convert_to_binary(x, 16)
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