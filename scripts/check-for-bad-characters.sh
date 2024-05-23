#!/bin/bash

# Define the root directory where your scripts are located
rootDirectory="~/smb_bench/scripts"

# Find all script files recursively from the root directory
scriptFiles=$(find "$rootDirectory" -type f -name "*.sh")

# Define a regular expression to match invalid characters (non-printable ASCII characters)
invalidCharacterRegex='[^[:print:]]'

# Iterate through each script file
while IFS= read -r scriptFile; do
    # Check if the script file exists
    if [[ -f "$scriptFile" ]]; then
        # Check if the script content contains any invalid characters
        invalidLines=$(grep -n "$invalidCharacterRegex" "$scriptFile" | cut -d ":" -f 2-)
        
        # If invalid characters are found, output the file name and invalid lines
        if [[ -n "$invalidLines" ]]; then
            echo "Invalid characters found in $scriptFile:"
            echo "$invalidLines"
        fi
    fi
done <<< "$scriptFiles"

