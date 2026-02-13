#!/bin/bash

# scripts/common/env.sh
# Shared environment variable detection and exports for KOSAIO scripts.

# Only enable strict mode if NOT running interactively
if [[ "$-" != *i* ]]; then
	set -Eeuo pipefail
fi

# Resolve KOSAIO_DIR correctly relative to the script location
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

# Detect root based on current folder name
if [[ "$(basename "$DIR")" == "common" ]]; then
	DETECTED_KOSAIO_DIR="$(dirname "$(dirname "$DIR")")"
elif [[ "$(basename "$DIR")" == "scripts" ]]; then
	DETECTED_KOSAIO_DIR="$(dirname "$DIR")"
else
	DETECTED_KOSAIO_DIR="$DIR"
fi

if [ -z "${KOSAIO_DIR:-}" ] || [ ! -d "${KOSAIO_DIR}/scripts" ]; then
	export KOSAIO_DIR="$DETECTED_KOSAIO_DIR"
fi

# Load kosaio.cfg if it exists (mostly for PROJECTS_HOST_DIR on host)
if [ -f "${KOSAIO_DIR}/kosaio.cfg" ]; then
	# Extract variables safely (allowing comments and ignoring them)
	while IFS='=' read -r key value; do
		[[ "$key" =~ ^#.* ]] && continue
		[[ -z "$key" ]] && continue
		# Trim whitespace and quotes
		key=$(echo "$key" | xargs)
		value=$(echo "$value" | xargs | sed 's/^"//;s/"$//')
		
		case "$key" in
			PROJECTS_HOST_DIR) export PROJECTS_HOST_DIR="${value%/}" ;;
			TOOL) export KOSAIO_TOOL="$value" ;;
			CONTAINER_NAME) export KOSAIO_CONTAINER_NAME="$value" ;;
		esac
	done < "${KOSAIO_DIR}/kosaio.cfg"
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

# On Host, if we have PROJECTS_HOST_DIR, use it for PROJECTS_DIR
if [ ! -f /.dockerenv ] && [ -n "${PROJECTS_HOST_DIR:-}" ]; then
	# If PROJECTS_DIR is unset or points to the default container path, override it
	if [ -z "${PROJECTS_DIR:-}" ] || [ "${PROJECTS_DIR}" == "/opt/projects" ]; then
		export PROJECTS_DIR="$PROJECTS_HOST_DIR"
	fi
else
	export PROJECTS_DIR="${PROJECTS_DIR:-/opt/projects}"
fi

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
	# PRIORITY: 
	#   1. KOSAIO_DEV_MODE=1 (Forced Host/Dev)
	#   2. KOSAIO_DEV_MODE=0 (Forced Container/Sys)
	#   3. Persistent state file (dev-switch)
	
	local use_dev=0
	if [ "${KOSAIO_DEV_MODE:-}" = "1" ]; then
		use_dev=1
	elif [ "${KOSAIO_DEV_MODE:-}" = "0" ]; then
		use_dev=0
	elif [ -f "${state_file}" ]; then
		use_dev=1
	fi

	local final_path
	if [ "$use_dev" = "1" ]; then
		# Host / Dev Mode always uses kosaio-dev root
		final_path="${KOSAIO_DEV_ROOT}/${tool}"
	else
		# System / Container Mode
		case "$tool" in
			kos|kos-ports|sh-elf|arm-eabi|aicaos|extras|bin)
				final_path="${DREAMCAST_SDK}/${tool}"
				;;
			*)
				# Registry tools/libs go to extras/
				final_path="${DREAMCAST_SDK}/extras/${tool}"
				;;
		esac

		# 2. AUTO-PIVOT (Smart Detection)
		# If the system path is missing but we are on a HOST, check if the dev path exists.
		# This prevents "environ.sh missing" errors if the user is running on host 
		# and has a local workspace ready, but hasn't explicitly switched mode.
		if [ ! -f /.dockerenv ] && [ ! -d "$final_path" ]; then
			if [ -d "${KOSAIO_DEV_ROOT}/${tool}" ]; then
				final_path="${KOSAIO_DEV_ROOT}/${tool}"
			fi
		fi
	fi

	echo "${final_path}"
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
