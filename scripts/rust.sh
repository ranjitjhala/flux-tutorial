#!/bin/bash

# Script to convert text files: keep flux code blocks unchanged, comment out everything else
# Usage: ./convert_to_rs.sh input_file.txt

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <input_file>" >&2
    exit 1
fi

input_file="$1"

if [[ ! -f "$input_file" ]]; then
    echo "Error: File '$input_file' does not exist" >&2
    exit 1
fi

# State variables
in_flux_block=false

echo "/*"
# Process the file line by line
while IFS= read -r line || [[ -n "$line" ]]; do
    # Check if line starts a flux code block
    if [[ "$line" =~ ^\`\`\`flux ]]; then
        in_flux_block=true
        echo "*/"
        echo ""
        echo ""
        echo ""
    # Check if line ends any code block (only after we've seen START)
    elif [[ "$in_flux_block" == "true" && "$line" == '```' ]]; then
        echo ""
        echo ""
        echo ""
        echo "/*"
        in_flux_block=false
    # If we're inside a flux block, echo the actual line
    elif [[ "$in_flux_block" == "true" ]]; then
        echo "$line"
    # Otherwise, just echo the commented out line
    else
        echo "$line"
    fi
done < "$input_file"
echo "*/"