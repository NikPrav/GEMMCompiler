#!/bin/bash

# Set the directory where your Verilog files are located
verilog_directory="$PWD/GEMMCompiler/hardware"

# Check if the directory exists
if [ ! -d "$verilog_directory" ]; then
    echo "Error: Directory '$verilog_directory' does not exist."
    exit 1
fi

# Navigate to the Verilog directory
cd "$verilog_directory" || exit 1

# The first argument is the output file
output_file="$1"
shift

# Compile the Verilog files in the specified order
iverilog -o "$output_file" "$@"

echo "Compilation complete."