#!/bin/bash

echo "Running application tests..."

if [ ! -f "app/index.html" ]; then
    echo "Test Failed: index.html not found"
    exit 1
fi

if [ ! -f "app/style.css" ]; then
    echo "Test Failed: style.css not found"
    exit 1
fi

if grep -q "<html" app/index.html && \
   grep -q "<body" app/index.html && \
   grep -q "</html>" app/index.html; then
    echo "Test Passed: Valid HTML structure found"
else
    echo "Test Failed: Invalid HTML structure"
    exit 1
fi

echo "Test Passed: Application files and content verified"
exit 0