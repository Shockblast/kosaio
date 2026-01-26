#!/bin/bash
# scripts/engine/ports/checks.sh

function _ports_check_exists() {
	if [ ! -d "${KOS_PORTS_DIR}" ]; then
		log_error "kos-ports not found. Clone it first: kosaio clone kos-ports"
		return 1
	fi
}

function _ports_check_requirements() {
	if [ ! -f "${KOS_DIR}/environ.sh" ]; then
		log_error "KOS environment not found (environ.sh missing)."
		return 1
	fi
}
