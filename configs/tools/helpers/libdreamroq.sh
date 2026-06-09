#!/bin/bash
# configs/tools/helpers/libdreamroq.sh
# Tool hooks for libdreamroq: KOS_PORTS integration, symlink management
# Loaded automatically by helper_loader.sh

kosaio_tool_info() {
	local tool_dir=$(__get_tool_dir)
	local status="${C_RED}Not Compiled${C_RESET}"
	local kos_ports_status="${C_GREEN}Found${C_RESET}"

	if [ ! -d "${KOS_PORTS}" ]; then
		kos_ports_status="${C_RED}MISSING${C_RESET}"
	fi

	[ -f "${tool_dir}/libdreamroq.a" ] && status="${C_GREEN}Compiled${C_RESET}"

	log_box --info "libdreamroq: RoQ Video Library" \
		"${C_YELLOW}Context:${C_RESET} High performance RoQ video decoding for Dreamcast." \
		"${C_YELLOW}Status:${C_RESET}  ${status}" \
		"${C_YELLOW}KOS-PORTS:${C_RESET} ${kos_ports_status}" \
		"${C_YELLOW}Path:${C_RESET}    ${tool_dir}" \
		"${C_YELLOW}Usage:${C_RESET}   Add ${C_CYAN}-ldreamroq${C_RESET} to your Makefile."
}

kosaio_tool_build() {
	local tool_dir=$(__get_tool_dir)

	[ -d "$tool_dir" ] || { log_error "libdreamroq source missing. Run 'kosaio clone ${ID}' first."; return 1; }

	if [ -z "${KOS_BASE:-}" ]; then
		log_error "KOS_BASE is not set. KOS environment must be loaded to build libdreamroq."
		return 1
	fi

	if [ -z "${KOS_PORTS:-}" ] || [ ! -d "${KOS_PORTS}" ]; then
		log_error "KOS_PORTS directory not found at '${KOS_PORTS:-unset}'. Install kos-ports first."
		return 1
	fi

	log_info --draw-line "Building libdreamroq..."

	mkdir -p "${KOS_PORTS}/include"
	(cd "${tool_dir}" && make defaultall)
}

kosaio_tool_apply() {
	local tool_dir=$(__get_tool_dir)
	local link_path="${KOS_PORTS}/include/dreamroq"

	log_info "Verifying libdreamroq installation..."

	if [ -d "${link_path}" ]; then
		log_success "libdreamroq is ready in KOS-PORTS."
	else
		if [ -L "${link_path}" ]; then
			log_warn "Dangling symlink detected for dreamroq headers. Fixing..."
		else
			log_warn "Headers symlink missing. Attempting to fix..."
		fi

		if [ -d "${tool_dir}/include" ]; then
			mkdir -p "${KOS_PORTS}/include"
			ln -sf "../${ID}/include" "${link_path}"
			log_success "Headers link restored."
		else
			log_error "Cannot fix symlink: Source include directory missing at ${tool_dir}/include"
			return 1
		fi
	fi
}
