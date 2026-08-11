#!/bin/bash

set -e

echo "Running application tests..."

if [ ! -f app/index.html ]; then
    echo "Test Failed: index.html missing"
    exit 1
fi

if ! grep -q "DevOps Pipeline" app/index.html; then
    echo "Test Failed: Expected application content not found"
    exit 1
fi

echo "Test Passed: index.html exists"
echo "Test Passed: Application content verified"
echo "All tests passed."