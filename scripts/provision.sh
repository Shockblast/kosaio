#!/bin/bash
# KOSAIO Provisioning Script
# Installs dependencies, sets up directories, and configures the environment.
# Can be used in Docker or on a fresh Host (Ubuntu/Debian).

set -Eeuo pipefail

# --- Configuration ---
KOSAIO_DIR="${KOSAIO_DIR:-/opt/kosaio}"
PROJECTS_DIR="${PROJECTS_DIR:-/opt/projects}"
DREAMCAST_SDK="${DREAMCAST_SDK:-/opt/toolchains/dc}"


# --- 1. System Update & Dependencies ---
echo ">>> [PROVISION] Updating System..."
apt-get update && apt-get upgrade -y

# Source KOSAIO libraries for dependency management
source "${KOSAIO_DIR}/scripts/common/ui.sh"
source "${KOSAIO_DIR}/scripts/common/deps.sh"

# Install Core SDK Dependencies using centralized logic
if ! kosaio_install_core_sdk_deps; then
	echo "ERROR: Failed to install core dependencies."
	exit 1
fi

apt-get clean
rm -rf /var/lib/apt/lists/*

# --- 2. Environment Setup ---
echo ">>> [PROVISION] Setting up Git Defaults..."
git config --global pull.rebase true
git config --global core.fileMode false
# Safe directory for generic /opt/projects
git config --global --add safe.directory '*'

# --- 3. Directory Structure ---
echo ">>> [PROVISION] Creating Directory Structure..."
TARGET_DIRS=(
	"${KOSAIO_DIR}"
	"${PROJECTS_DIR}"
	"${DREAMCAST_SDK}"
	"${DREAMCAST_SDK}/bin"
	"${DREAMCAST_SDK}/extras"
)

for dir in "${TARGET_DIRS[@]}"; do
	if [ ! -d "$dir" ]; then
		mkdir -p "$dir"
		echo "	Created: $dir"
	fi
done

# --- 4. Permissions ---
# If running as root (likely in Docker/Sudo), ensure /opt is accessible
# We default to 755/root:root which is standard for system-wide tools
echo ">>> [PROVISION] Setting Permissions on /opt..."
chmod -R 755 /opt
chown -R root:root /opt

echo ">>> [PROVISION] Setup Complete!"
