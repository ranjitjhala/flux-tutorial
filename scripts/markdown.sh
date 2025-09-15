#!/bin/bash

# Script to replace "``` flux" with "```rust, editable" in markdown files
# Usage: ./convert.sh [file1.md file2.md ...] or ./convert.sh (processes all *.md files)

# Function to process a single file
process_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Warning: File '$file' does not exist, skipping..."
        return 1
    fi

    echo "Processing: $file"

    # Use sed to replace lines that start with "``` flux" with "```rust, editable"
    # -i '' for in-place editing on macOS, -i for Linux
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/^``` flux$/```rust, editable/' "$file"
    else
        sed -i 's/^``` flux$/```rust, editable/' "$file"
    fi

    echo "Completed: $file"
}

# Main script logic
if [[ $# -eq 0 ]]; then
    # No arguments provided, process all .md files in current directory and subdirectories
    echo "No files specified, processing all *.md files..."

    # Find all .md files and process them
    while IFS= read -r -d '' file; do
        process_file "$file"
    done < <(find . -name "*.md" -type f -print0)

    if [[ ! $(find . -name "*.md" -type f) ]]; then
        echo "No .md files found in current directory and subdirectories."
    fi
else
    # Process specified files
    for file in "$@"; do
        # Add .md extension if not present
        if [[ "$file" != *.md ]]; then
            file="${file}.md"
        fi
        process_file "$file"
    done
fi

echo "Conversion complete!"