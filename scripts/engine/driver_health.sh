set -Eeuo pipefail
# driver_health.sh - Integration driver for System Health
# This is a library of functions, not intended for direct execution.

# Returns Exit Codes:
# 0: OK (Installed & Healthy)
# 1: Not Installed
# 2: Broken
# 3: Dependencies Missing
# 4: Manifest Error

# Source dependencies (fail loudly if missing - these are critical)
source "${KOSAIO_DIR}/scripts/common/deps.sh"


function health_check() {
	local TARGET_ID="${1,,}"

	# 1. Resolve Target Type & Manifest Path via Python Engine (SSoT)
	# Delegating all identification and expansion (aliases) to the Python Engine
	local target_type
	local MANIFEST
	
	target_type=$(python3 "${KOSAIO_DIR}/scripts/engine/py/main.py" get_type "$TARGET_ID" 2>/dev/null) || target_type="unknown"
	MANIFEST=$(python3 "${KOSAIO_DIR}/scripts/engine/py/main.py" get_manifest_path "$TARGET_ID" 2>/dev/null) || MANIFEST=""

	# 2. Logic Dispatch
	case "$target_type" in
		"port")
			if ports_is_installed "$TARGET_ID" >/dev/null 2>&1; then
				return 0
			else
				return 1
			fi
			;;
		
		"tool"|"core")
			if [ -z "$MANIFEST" ] || [ ! -f "$MANIFEST" ]; then
				log_error "Manifest for '${TARGET_ID}' not found."
				return 4
			fi

			source "$MANIFEST"

			# Check OS Dependencies (Manifest-defined)
			if [ -n "${DEPS:-}" ] && ! kosaio_check_apt_deps $DEPS; then
				return 3
			fi

			# Execute Manifest Health Logic
			if [ "$(type -t reg_check_health)" == "function" ]; then
				reg_check_health
				return $?
			else
				# Minimal default logic: Directory check
				local TOOL_DIR
				TOOL_DIR=$(validate_get_tool_path "$ID" 2>/dev/null) || TOOL_DIR=$(kosaio_get_tool_dir "$ID")
				[ -d "$TOOL_DIR" ] && return 0 || return 1
			fi
			;;

		*)
			# Unknown type but maybe manifest exists (forced resolution)
			if [ -n "$MANIFEST" ] && [ -f "$MANIFEST" ]; then
				source "$MANIFEST"
				if [ "$(type -t reg_check_health)" == "function" ]; then
					reg_check_health
					return $?
				fi
			fi
			return 4 # Not found / Manifest error
			;;
	esac
}
