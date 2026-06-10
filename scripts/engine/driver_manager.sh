#!/bin/bash
set -Eeuo pipefail
# driver_manager.sh - Integration driver for Tool Registry
# This is a library of functions, not intended for direct execution.
#
# REFACTORED: Uses Python engine for manifest path resolution (Single Source of Truth)

ENGINE_PY="${KOSAIO_DIR}/scripts/engine/py/main.py"

function kosaio_manager_execute() {
	local COMMAND="${1,,}"
	local TARGET_ID="${2,,}"
	shift 2

	# Find manifest using Python engine (Single Source of Truth)
	local MANIFEST
	MANIFEST=$(python3 "$ENGINE_PY" get_manifest_path "$TARGET_ID" 2>/dev/null) || {
		log_error "Target '${TARGET_ID}' not found in registry."
		return 1
	}

	# Load mandatory tool configuration
	kosaio_load_tool_config "$TARGET_ID" || return 1

	# Load tool-specific helpers (PREBUILD_FUNC, etc.)
	kosaio_load_tool_helpers "$TARGET_ID"

	# Source template (generic kosaio_reg_* functions)
	# shellcheck source=/dev/null
	source "${KOSAIO_DIR}/scripts/registry/process-standard.sh"

	# If a custom manifest exists (not the template itself), source it as override
	if [ "$MANIFEST" != "${KOSAIO_DIR}/scripts/registry/process-standard.sh" ]; then
		# shellcheck disable=SC1090
		source "$MANIFEST"
	fi

	case "$COMMAND" in
		"install")
			if [ -n "${DEPS:-}" ]; then
			read -ra DEPS_ARR <<< "$DEPS"
			kosaio_install_apt_deps "${DEPS_ARR[@]}"
		fi
			if [ "$(type -t kosaio_reg_install)" == "function" ]; then
				kosaio_reg_install "$@"
			else
				log_error "Target '${ID}' does not support installation."
				return 1
			fi
			;;
		"uninstall")
			if [ "$(type -t kosaio_reg_uninstall)" == "function" ]; then
				kosaio_reg_uninstall "$@"
			else
				log_error "Target '${ID}' does not support uninstallation."
				return 1
			fi
			;;
		"update")
			if [ "$(type -t kosaio_reg_update)" == "function" ]; then
				kosaio_reg_update "$@"
			else
				log_error "Target '${ID}' does not support updates."
				return 1
			fi
			;;
		"info")
			log_info --draw-line "Information: ${ID}"
			printf "${C_CYAN}Name:        ${C_RESET}%s\n" "${NAME}"
			printf "${C_CYAN}Type:        ${C_RESET}%s\n" "${TYPE}"
			printf "${C_CYAN}Tags:        ${C_RESET}%s\n" "${TAGS}"
			printf "${C_CYAN}Description: ${C_RESET}%s\n" "${DESC}"
			[ -z "${REPO:-}" ] || printf "${C_CYAN}Repository:  ${C_RESET}%s\n" "${REPO}"
			
			# Call custom info if available
			if [ "$(type -t kosaio_reg_info)" == "function" ]; then
				echo ""
				kosaio_reg_info "$@"
			fi
			;;
		"build"|"apply"|"apply-config"|"reset"|"checkout"|"clone"|"clean"|"export")
			local func_suffix="${COMMAND//-/_}"
			FUNC_NAME="kosaio_reg_${func_suffix}"
			if [ "$(type -t "${FUNC_NAME}")" == "function" ]; then
				${FUNC_NAME} "$@"
			else
				log_error "Action '${COMMAND}' is not supported by ${ID}"
				return 1
			fi
			;;
		*)
			log_error "Unknown command '$COMMAND' for tool manager."
			return 1
			;;
	esac
}
