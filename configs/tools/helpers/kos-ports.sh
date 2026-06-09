#!/bin/bash
# configs/tools/helpers/kos-ports.sh
# Tool hooks for kos-ports: custom build (--force-build guard), install (clone + build only),
# update (pull + submodules), uninstall (rm -rf)
# Loaded automatically by helper_loader.sh

kosaio_tool_build() {
	local force_build=false
	for arg in "$@"; do
		[ "$arg" == "--force-build" ] && { force_build=true; break; }
	done

	if [ "$force_build" = false ]; then
		log_box --type=warn "MASSIVE BUILD DETECTED" \
			"Target: ALL kos-ports libraries (Huge compiling time!)" \
			"${C_YELLOW}Tip:${C_RESET} Use ${C_CYAN}kosaio clone kos-ports${C_RESET} to explore first." \
			"${C_YELLOW}Tip:${C_RESET} Then install specific ports: ${C_CYAN}kosaio install libpng${C_RESET}" \
			"To force compile EVERYTHING, use: ${C_YELLOW}--force-build${C_RESET}"
		return 0
	fi

	log_info --draw-line "Building KOS-PORTS (Build system utilities)..."
	(cd "${KOS_PORTS}/utils" && ./build-all.sh || true)
}

kosaio_tool_install() {
	local force_build=false
	for arg in "$@"; do
		[ "$arg" == "--force-build" ] && { force_build=true; break; }
	done

	if [ "$force_build" = false ]; then
		kosaio_tool_build "$@"
		return $?
	fi

	log_info --draw-line "Cloning KOS-PORTS repository..."
	kosaio_git_clone https://github.com/KallistiOS/kos-ports.git "${KOS_PORTS}"

	kosaio_tool_build "$@"

	log_success "KOS-PORTS installation complete."
}

kosaio_tool_update() {
	kosaio_git_common_update "${KOS_PORTS}"
	(cd "${KOS_PORTS}" && git submodule update --init --recursive)
}

kosaio_tool_uninstall() {
	rm -rf "${KOS_PORTS}"
	log_success "KOS-PORTS removed."
}
