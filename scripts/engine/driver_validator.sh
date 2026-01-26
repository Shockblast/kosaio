#!/bin/bash
set -Eeuo pipefail
# driver_validator.sh - Centralized Validation Logic
# Decouples validation from the main orchestrator (kosaio)
#
# REFACTORED: Now delegates ALL logic to Python engine (Single Source of Truth)
# The Bash fallback has been removed to eliminate code duplication.

ENGINE_PY="${KOSAIO_DIR}/scripts/engine/py/main.py"

function validate_get_target_type() {
	local target="$1"
	local action="${2:-}"

	[ -z "$target" ] && return 1

	# Delegate to Python Engine (Single Source of Truth)
	local result
	local exit_code

	if [ -n "$action" ]; then
		result=$(python3 "$ENGINE_PY" validate_target "$target" --action "$action" 2>&1)
	else
		result=$(python3 "$ENGINE_PY" validate_target "$target" 2>&1)
	fi
	exit_code=$?

	# Handle exit codes from Python
	case $exit_code in
		0)
			# Success - output is the target type
			echo "$result"
			return 0
			;;
		1)
			# Target not found
			log_error "Target '${target}' not found in registry or ports."
			return 1
			;;
		3)
			# Dependency missing (e.g., kos-ports required)
			# Python already printed the helpful message to stderr
			log_warn "$(echo "$result" | head -n 1)"
			log_info "You must install the dependency first:"
			echo -e "  ${C_YELLOW}kosaio clone kos-ports${C_RESET}\n"
			return 3
			;;
		*)
			# Unexpected error
			log_error "Validation failed: $result"
			return $exit_code
			;;
	esac
}

# Utility: Get tool path (delegates to Python)
function validate_get_tool_path() {
	local tool="$1"
	local mode="${2:-}"

	if [ -n "$mode" ]; then
		python3 "$ENGINE_PY" get_tool_path "$tool" --mode "$mode"
	else
		python3 "$ENGINE_PY" get_tool_path "$tool"
	fi
}
