#!/bin/bash
# analyze.sh - Custom greeting analysis tool
# Demonstrates using scripts from bin/ directory

input_file=$1
output_file=$2

echo "=== Greeting Analysis ===" > "$output_file"
echo "File: $(basename $input_file)" >> "$output_file"
echo "Characters: $(wc -m < $input_file)" >> "$output_file"
echo "Words: $(wc -w < $input_file)" >> "$output_file"
echo "Lines: $(wc -l < $input_file)" >> "$output_file"

# Check if greeting is enthusiastic (ends with !)
if grep -q '!' "$input_file"; then
    echo "Enthusiasm: HIGH" >> "$output_file"
else
    echo "Enthusiasm: LOW" >> "$output_file"
fi

# Check if name contains 'Alice'
if grep -q 'Alice' "$input_file"; then
    echo "Special Guest: YES" >> "$output_file"
else
    echo "Special Guest: NO" >> "$output_file"
fi