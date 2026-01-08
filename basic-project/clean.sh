#!/bin/bash
set -e

# Attempts to source environment if not already set
if [ -z "$KOS_BASE" ]; then
    if [ -f "/opt/toolchains/dc/kos/environ.sh" ]; then
        source /opt/toolchains/dc/kos/environ.sh
    fi
fi

echo "Cleaning project..."
make clean.all
echo "Clean complete."
