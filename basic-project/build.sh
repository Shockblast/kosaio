#!/bin/bash
set -e

# Attempts to load the current KOSAIO environment
if [ -z "$KOS_BASE" ]; then
	if [ -f "/opt/kosaio/scripts/common/kos-pivot.sh" ]; then
		source /opt/kosaio/scripts/common/kos-pivot.sh
		kosaio_kos_pivot > /dev/null
	fi
fi

# Final check
if [ -z "$KOS_BASE" ]; then
	echo -e "\033[1;31m[ERROR]\033[0m KOS_BASE is not set. Please run 'kos-env' or enter via 'kosaio-shell'."
	exit 1
fi

echo "Building project..."
make -j$(nproc)

# Fix permissions for build artifacts
# Uses the current directory (.) as reference for ownership
echo "Fixing permissions..."
if [ -d "build" ]; then
	chown -R --reference=. build
fi
if [ -d "release" ]; then
	chown -R --reference=. release
fi

echo "Build complete."
