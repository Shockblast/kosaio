#!/bin/bash
# scripts/engine/ports/checks.sh

function _ports_check_exists() {
	if [ ! -d "${KOS_PORTS_DIR}" ]; then
		log_error "kos-ports not found at: ${KOS_PORTS_DIR}"
		
		# If we are in Host/Dev context, offer to clone it to the workspace
		if [ "${KOSAIO_DEV_MODE:-0}" == "1" ] || [[ "${KOS_PORTS_DIR}" == "${KOSAIO_DEV_ROOT}"* ]]; then
			if confirm "kos-ports is missing in your HOST workspace. Do you want to clone it now?" "Y"; then
				# Use the registry command to clone it correctly
				manager_execute "clone" "kos-ports"
				# Verify if it worked
				[ -d "${KOS_PORTS_DIR}" ] && return 0
			fi
		fi

		log_info "Tip: Run 'kosaio clone kos-ports' first."
		return 1
	fi
}

function _ports_check_requirements() {
	if [ ! -f "${KOS_DIR}/environ.sh" ]; then
		log_error "KOS environment not found (environ.sh missing)."
		return 1
	fi
}
