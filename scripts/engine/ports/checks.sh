#!/bin/bash
set -Eeuo pipefail
# scripts/engine/ports/checks.sh

function _ports_check_exists() {
	if [ ! -d "${KOS_PORTS}" ]; then
		log_error "kos-ports not found at: ${KOS_PORTS}"
		
		# If we are in Host/Dev context, offer to clone it to the workspace
		if [ "${KOSAIO_DEV_MODE:-0}" == "1" ] || [[ "${KOS_PORTS}" == "${KOSAIO_DEV_ROOT}"* ]]; then
			if confirm "kos-ports is missing in your HOST workspace. Do you want to clone it now?" "Y"; then
				# Use the registry command to clone it correctly
				kosaio_manager_execute "clone" "kos-ports"
				# Verify if it worked
				[ -d "${KOS_PORTS}" ] && return 0
			fi
		fi

		log_info "Tip: Run 'kosaio clone kos-ports' first."
		return 1
	fi
}

function _ports_check_requirements() {
	local soft="${1:-false}"
	if [ ! -f "${KOS_DIR}/environ.sh" ]; then
		if [ "$soft" == "true" ]; then
			log_warn "KOS environment not found (environ.sh missing) at: ${KOS_DIR}"
			log_info "Note: Operations depending on KOS rules might fail until 'kosaio apply kos' is run."
			return 0
		fi
		log_error "KOS environment not found (environ.sh missing)."
		log_info "Path checked: ${KOS_DIR}"
		log_info "Tip: Run 'kosaio apply kos' to generate the environment file."
		return 1
	fi
}
