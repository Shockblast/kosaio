#!/bin/bash
set -Eeuo pipefail
# driver_manager.sh - Integration driver for Tool Registry
# This is a library of functions, not intended for direct execution.
#
# REFACTORED: Uses Python engine for manifest path resolution (Single Source of Truth)

ENGINE_PY="${KOSAIO_DIR}/scripts/engine/py/main.py"

function manager_execute() {
	local COMMAND="${1,,}"
	local TARGET_ID="${2,,}"
	shift 2

	# Find manifest using Python engine (Single Source of Truth)
	local MANIFEST
	MANIFEST=$(python3 "$ENGINE_PY" get_manifest_path "$TARGET_ID" 2>/dev/null) || {
		log_error "Target '${TARGET_ID}' not found in registry."
		return 1
	}

	# Source Manifest (Scoped to this function/process)
	source "$MANIFEST"

	case "$COMMAND" in
		"install")
			[ -n "${DEPS:-}" ] && kosaio_install_apt_deps $DEPS
			if [ "$(type -t reg_install)" == "function" ]; then
				reg_install "$@"
			else
				log_error "Target '${ID}' does not support installation."
				return 1
			fi
			;;
		"uninstall")
			if [ "$(type -t reg_uninstall)" == "function" ]; then
				reg_uninstall "$@"
			else
				log_error "Target '${ID}' does not support uninstallation."
				return 1
			fi
			;;
		"update")
			if [ "$(type -t reg_update)" == "function" ]; then
				reg_update "$@"
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
			if [ "$(type -t reg_info)" == "function" ]; then
				echo ""
				reg_info "$@"
			fi
			;;
		"build"|"apply"|"reset"|"checkout"|"clone"|"clean"|"export")
			FUNC_NAME="reg_${COMMAND}"
			if [ "$(type -t ${FUNC_NAME})" == "function" ]; then
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
