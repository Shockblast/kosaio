#!/bin/bash

# scripts/common/env.sh
# Shared environment variable detection and exports for KOSAIO scripts.

# Only enable strict mode if NOT running interactively
if [[ "$-" != *i* ]]; then
	set -Eeuo pipefail
fi

# Detect KOSAIO_DIR if not set
if [ -z "${KOSAIO_DIR:-}" ]; then
	# Assume script is located in <KOSAIO_DIR>/scripts/... or <KOSAIO_DIR>/scripts/common
	# Resolve symlinks to find the real source location
	SOURCE="${BASH_SOURCE[0]}"
	while [ -h "$SOURCE" ]; do
	  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
	  SOURCE="$(readlink "$SOURCE")"
	  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
	done
	ENV_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

	# If we are in 'scripts/common', KOSAIO_DIR is two levels up
	if [[ "$(basename "$ENV_DIR")" == "common" ]]; then
		export KOSAIO_DIR="$(dirname "$(dirname "$ENV_DIR")")"
	# If we are in 'scripts', KOSAIO_DIR is one level up
	elif [[ "$(basename "$ENV_DIR")" == "scripts" ]]; then
		export KOSAIO_DIR="$(dirname "$ENV_DIR")"
	else
		# Fallback default
		export KOSAIO_DIR="/opt/kosaio" 
	fi
fi

# Framework Update Branch (Defaults to current branch)
if [ -z "${KOSAIO_BRANCH:-}" ]; then
	if [ -d "${KOSAIO_DIR}/.git" ]; then
		export KOSAIO_BRANCH=$(git -C "${KOSAIO_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "master")
	else
		export KOSAIO_BRANCH="master"
	fi
fi

# SDK Constants & Defaults
export DREAMCAST_SDK="${DREAMCAST_SDK:-/opt/toolchains/dc}"
export PROJECTS_DIR="${PROJECTS_DIR:-/opt/projects}"
export KOSAIO_DEV_ROOT="${PROJECTS_DIR}/kosaio-dev"
export KOS_MAKE="${KOS_MAKE:-make}"

# State Directory for Dev Mode
KOSAIO_STATE_DIR="${HOME}/.kosaio/states"

# Logging Configuration
# FULL: [YYYY-MM-DD HH:MM:SS] INFO: Message
# SHORT: [HH:MM:SS] INFO: Message
# SIMPLE: INFO: Message
export KOSAIO_LOG_MODE="${KOSAIO_LOG_MODE:-SIMPLE}"

# --- Smart Path Detection Helpers ---

# Returns the active directory for a given tool (kos, dcload-ip, etc.)
# Based on KOSAIO_DEV_MODE env var or persistent state files.
#
# =============================================================================
# IMPORTANT: PATH RESOLUTION HIERARCHY
# =============================================================================
# ... (keeping existing comments) ...
# =============================================================================
function kosaio_get_tool_dir() {
	local tool="$1"
	local state_file="${KOSAIO_STATE_DIR}/${tool}_dev"
	local base_dir

	# 1. Determine base path based on mode and tool criticality
	if [ "${KOSAIO_DEV_MODE:-0}" = "1" ] || [ -f "${state_file}" ]; then
		# Host / Dev Mode always uses kosaio-dev root
		base_dir="${KOSAIO_DEV_ROOT}"
	else
		# System / Container Mode
		case "$tool" in
			kos|kos-ports|sh-elf|arm-eabi|aicaos|extras|bin)
				base_dir="${DREAMCAST_SDK}"
				;;
			*)
				# Registry tools/libs go to extras/
				base_dir="${DREAMCAST_SDK}/extras"
				;;
		esac
	fi

	echo "${base_dir}/${tool}"
}

# --- Legacy and Global Exports ---
export KOS_DIR=$(kosaio_get_tool_dir "kos")
export KOS_PORTS_DIR=$(kosaio_get_tool_dir "kos-ports")

export KOS_BASE="${KOS_DIR}"
export KOS_PORTS="${KOS_PORTS_DIR}"
export KOS_PORTS_BASE="${KOS_PORTS_DIR}"

# Binaries location: We move it to extras/bin to keep root clean
export DREAMCAST_BIN_PATH="${DREAMCAST_SDK}/extras/bin"
export DREAMCAST_SDK_EXTRAS="${DREAMCAST_SDK}/extras"

if [ "${KOSAIO_DEV_MODE:-0}" = "1" ]; then
	export DREAMCAST_BIN_PATH="${KOSAIO_DEV_ROOT}/bin"
fi

# Inject Extras Bin into PATH
if [ -d "${DREAMCAST_BIN_PATH}" ]; then
	export PATH="${PATH}:${DREAMCAST_BIN_PATH}"
fi

# Ensure CMake wrappers are in PATH (Vital for modern KOS Ports)
if [ -d "${KOS_BASE}/utils/build_wrappers" ]; then
	export PATH="${KOS_BASE}/utils/build_wrappers:${PATH}"
fi

# --- Environment Validation Functions ---

function kosaio_check_environment_vars() {
	local errors=0
	local required_vars=(
		"DREAMCAST_SDK"
		"PROJECTS_DIR"
		"KOS_BASE"
		"KOS_PORTS"
	)

	for var in "${required_vars[@]}"; do
		if [ -z "${!var}" ]; then
			echo "FAIL: $var is NOT set."
			((errors++))
		elif [ ! -d "${!var}" ]; then
			# Not necessarily fatal for some wrappers, but worth noting
			: 
		fi
	done
	return $errors
}

function kosaio_check_toolchain() {
	if ! command -v sh-elf-gcc >/dev/null 2>&1; then
		echo "CRITICAL: sh-elf-gcc not found in PATH."
		return 1
	fi
	return 0
}

# --- Configuration Self-Healing ---

function ensure_bashrc_config() {
	local INIT_LINE="source ${KOSAIO_DIR}/scripts/shell-init.sh"
	local BASHRC="/root/.bashrc"
	
	if [ -f "$BASHRC" ]; then
		# Check if the line exists
		if ! grep -Fxq "$INIT_LINE" "$BASHRC"; then
			# If we are root (inside container), we can fix it
			if [ "$(id -u)" -eq 0 ]; then
				echo "" >> "$BASHRC"
				echo "# KOSAIO Auto-Init" >> "$BASHRC"
				echo "$INIT_LINE" >> "$BASHRC"
				# Quietly fixed
			fi
		fi
	fi
}
