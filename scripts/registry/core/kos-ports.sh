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

function reg_info() {
	log_box --info "KOS-PORTS: LIBRARY COLLECTION" \
		"${C_YELLOW}Context:${C_RESET} Collection of 3rd party libraries (SDL, zlib, GLdc, etc.)" \
		"${C_YELLOW}Usage:${C_RESET}   Install specific ports: ${C_CYAN}kosaio install <port_name>${C_RESET}" \
		"${C_YELLOW}List:${C_RESET}    Run ${C_CYAN}kosaio list${C_RESET} to see available ports." \
		"${C_YELLOW}Path:${C_RESET}    ${KOS_PORTS_DIR}" \
		"${C_YELLOW}Note:${C_RESET}    You need to clone first ${C_CYAN}kosaio clone kos-ports${C_RESET} to see available ports."
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
		log_box --type=warn "MASSIVE BUILD DETECTED" \
			"Target: ALL kos-ports libraries (Huge compiling time!)" \
			"${C_YELLOW}Tip:${C_RESET} Use ${C_CYAN}kosaio clone kos-ports${C_RESET} to explore first." \
			"${C_YELLOW}Tip:${C_RESET} Then install specific ports: ${C_CYAN}kosaio install libpng${C_RESET}" \
			"To force install EVERYTHING, use: ${C_YELLOW}--force-build${C_RESET}"
		return 0
	fi

	reg_clone
	reg_build
	log_success "KOS-PORTS installation complete."
}

function reg_update() {
	kosaio_git_common_update "${KOS_PORTS_DIR}"
	(cd "${KOS_PORTS_DIR}" && git submodule update --init --recursive)
}

function reg_uninstall() {
	rm -rf "${KOS_PORTS_DIR}"
	log_success "KOS-PORTS removed."
}
