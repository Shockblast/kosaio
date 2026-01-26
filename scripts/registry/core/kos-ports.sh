#!/bin/bash
set -Eeuo pipefail

# scripts/registry/core/kos-ports.sh
# Manifest for the KOS-PORTS library collection

ID="kos-ports"
NAME="KOS-PORTS"
DESC="Collection of libraries for KallistiOS (zlib, libpng, GLdc, etc.)"
TAGS="core,libraries,ports,dreamcast"
TYPE="core"
DEPS="git build-essential"

function reg_check_health() {
	[ -d "${KOS_PORTS_DIR}" ] || return 1
	return 0
}

function reg_clone() {
	log_info --draw-line "Cloning KOS-PORTS repository..."
	kosaio_git_clone https://github.com/KallistiOS/kos-ports.git "${KOS_PORTS_DIR}"
}

function reg_build() {
	[ -d "${KOS_PORTS_DIR}" ] || { log_error "KOS-PORTS source missing. Run 'kosaio clone kos-ports' first."; return 1; }
	log_info --draw-line "Building KOS-PORTS (Build system utilities)..."
	(cd "${KOS_PORTS_DIR}/utils" && ./build-all.sh || true)
}

function reg_install() {
	local force_build=false
	for arg in "$@"; do
		if [ "$arg" == "--force-build" ]; then
			force_build=true
			break
		fi
	done

	if [ "$force_build" = false ]; then
		log_warn "You are about to download and compile ALL kos-ports libraries."
		log_warn "This generates a lot of data and takes a long time."
		log_info "Tip: Use 'kosaio clone kos-ports' to download sources,"
		log_info "     then install specific ports as needed (e.g., 'kosaio install libpng')."
		log_warn "Tip: After cloning, you can also use 'kosaio list' to see all available ports."
		log_info "To force build everything, use: '${C_YELLOW}kosaio install kos-ports --force-build${C_RESET}'"
		return 0
	fi

	reg_clone
	reg_build
	log_success "KOS-PORTS installation complete."
}

function reg_update() {
	kosaio_git_common_update "${KOS_PORTS_DIR}"
	(cd "${KOS_PORTS_DIR}" && git submodule update --init --recursive)
	reg_build
}

function reg_uninstall() {
	rm -rf "${KOS_PORTS_DIR}"
	log_success "KOS-PORTS removed."
}
