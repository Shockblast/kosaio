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
		esac
	done < "${KOSAIO_DIR}/kosaio.cfg"
fi

# Framework Update Branch (Defaults to current branch)
if [ -z "${KOSAIO_BRANCH:-}" ]; then
	if [ -d "${KOSAIO_DIR}/.git" ]; then
		KOSAIO_BRANCH="$(git -C "${KOSAIO_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "master")"
	else
		KOSAIO_BRANCH="master"
	fi
	export KOSAIO_BRANCH
fi

# SDK Constants & Defaults
export DREAMCAST_SDK="${DREAMCAST_SDK:-/opt/toolchains/dc}"

# Container detection (Docker/Podman/etc)
IS_CONTAINER=0
if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
	IS_CONTAINER=1
fi

# On Host, if we have PROJECTS_HOST_DIR, use it for PROJECTS_DIR
if [ "$IS_CONTAINER" -eq 0 ] && [ -n "${PROJECTS_HOST_DIR:-}" ]; then
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
KOSAIO_STATE_DIR="${KOSAIO_DIR}/data/states"

# Library metadata (.mk files) for user projects
export KOSAIO_MK="${KOSAIO_DIR}/scripts/registry/mk"

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

	# Delegate to Python engine (Single Source of Truth) when available
	local ENGINE_PY="${KOSAIO_DIR}/scripts/engine/py/main.py"
	if [ -f "$ENGINE_PY" ] && command -v python3 >/dev/null 2>&1; then
		local py_result
		py_result=$(python3 "$ENGINE_PY" get_tool_path "$tool" 2>/dev/null) && {
			echo "$py_result"
			return 0
		}
	fi

	# Fallback: static resolution for bootstrap / minimal environments
	# New state system: data/states/host/<tool>
	local state_file="${KOSAIO_STATE_DIR}/host/${tool}"

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
		final_path="${KOSAIO_DEV_ROOT}/${tool}"
	else
		case "$tool" in
			kos|kos-ports|sh-elf|arm-eabi|aicaos|bin)
				final_path="${DREAMCAST_SDK}/${tool}"
				;;
			*)
				final_path="${KOSAIO_DIR}/data/repos/${tool}"
				;;
		esac

		# AUTO-PIVOT: on host, if system path missing, try dev path
		if [ "$IS_CONTAINER" -eq 0 ] && [ ! -d "$final_path" ]; then
			if [ -d "${KOSAIO_DEV_ROOT}/${tool}" ]; then
				final_path="${KOSAIO_DEV_ROOT}/${tool}"
			fi
		fi
	fi

	echo "${final_path}"
}

# --- Legacy and Global Exports ---
KOS_DIR="$(kosaio_get_tool_dir "kos")"
export KOS_DIR
KOS_PORTS="$(kosaio_get_tool_dir "kos-ports")"
export KOS_PORTS

export KOS_BASE="${KOS_DIR}"

# Binaries location: Host tools compiled for Dreamcast dev go here
export KOSAIO_BIN_PATH="${KOSAIO_DIR}/data/bin"

if [ "${KOSAIO_DEV_MODE:-0}" = "1" ]; then
	export KOSAIO_BIN_PATH="${KOSAIO_DEV_ROOT}/bin"
fi

# Inject Extras Bin into PATH
if [ -d "${KOSAIO_BIN_PATH}" ]; then
	export PATH="${PATH}:${KOSAIO_BIN_PATH}"
fi

# Ensure CMake wrappers are in PATH (Vital for modern KOS Ports)
if [ -d "${KOS_BASE}/utils/build_wrappers" ]; then
	export PATH="${KOS_BASE}/utils/build_wrappers:${PATH}"
fi

# --- Configuration Self-Healing ---

function ensure_bashrc_config() {
	local INIT_LINE="source ${KOSAIO_DIR}/scripts/shell-init.sh"
	local BASHRC="/root/.bashrc"
	
	if [ -f "$BASHRC" ]; then
		# Check if the line exists
		if ! grep -Fxq "$INIT_LINE" "$BASHRC"; then
			# If we are root (inside container), we can fix it
			if [ "$(id -u)" -eq 0 ]; then
				{
					echo ""
					echo "# KOSAIO Auto-Init"
					echo "$INIT_LINE"
				} >> "$BASHRC"
				# Quietly fixed
			fi
		fi
	fi
}
